<?php
declare(strict_types=1);

/**
 * profil_siswa.php — API Profil Siswa (SIAPOS APK)
 * Data selengkap halaman web profil_siswa.php: identitas siswa, sekolah
 * asal (+ mutasi jika ada), data ayah/ibu/wali, lampiran dokumen,
 * riwayat kelas, dan kategori siswa.
 *
 * Otentikasi: WAJIB header Authorization: Bearer <token> (dari login.php).
 * siswa_id TIDAK diambil dari input klien — selalu dari sesi token,
 * supaya siswa/wali hanya bisa melihat profil miliknya sendiri.
 *
 * aksi=update (POST JSON): simpan perubahan data siswa/sekolah/mutasi/ortu.
 * Body: {aksi:'update', data:{siswa, sekolah_asal, mutasi, orangtua}}.
 * siswa_id tetap dari sesi, bukan dari body.
 */

require_once __DIR__ . '/guard.php';

$ctx = sgSecure([
    'allowed_origins' => [
        'https://mtsbutambakberas.sch.id',
        'https://spmb.mtsbutambakberas.sch.id',
        // 'https://domain-lain-yang-sah.sch.id',
    ],
]);
$clientIp = $ctx['client_ip'];

if (!in_array($_SERVER['REQUEST_METHOD'], ['GET', 'POST'], true)) {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method tidak diizinkan', 'data' => []]);
    exit;
}

$pdo = null;
if (file_exists(__DIR__ . '/../../config/database.php')) {
    try {
        require_once __DIR__ . '/../../config/database.php';
    } catch (Throwable $e) {
        error_log('[profil-siswa-api] Gagal load config database: ' . $e->getMessage());
    }
}

function jsonOut(bool $success, string $message, array $data = [], int $status = 200): void {
    http_response_code($status);
    echo json_encode(['success' => $success, 'message' => $message, 'data' => $data], JSON_UNESCAPED_UNICODE);
    exit;
}

if (!$pdo) {
    error_log('[profil-siswa-api] Koneksi database tidak tersedia dari IP ' . $clientIp);
    jsonOut(false, 'Koneksi database tidak tersedia.', [], 500);
}

/* ── Autentikasi wajib ──
   role 'siswa' → user_id sesi = id siswa itu sendiri
   role 'wali'  → user_id sesi = id siswa anaknya (lihat login.php: wali
                  login menyimpan s.id, bukan id akun wali) */
$auth = sgAuthenticate($pdo, ['siswa', 'wali']);
if (!$auth) {
    jsonOut(false, 'Sesi tidak valid atau sudah kedaluwarsa. Silakan login ulang.', [], 401);
}
$siswa_id = $auth['user_id'];

function dbRow(PDO $pdo, string $sql, array $p = []): array {
    $s = $pdo->prepare($sql);
    $s->execute($p);
    return $s->fetch(PDO::FETCH_ASSOC) ?: [];
}
function dbRows(PDO $pdo, string $sql, array $p = []): array {
    $s = $pdo->prepare($sql);
    $s->execute($p);
    return $s->fetchAll(PDO::FETCH_ASSOC);
}
function nz($v, $fb = '') {
    return ($v !== null && $v !== '') ? $v : $fb;
}
/** Daftar kolom sungguhan (case-insensitive) dari sebuah tabel. */
function dbCols(PDO $pdo, string $table): array {
    static $cache = [];
    if (isset($cache[$table])) return $cache[$table];
    $cols = [];
    try {
        foreach ($pdo->query("SHOW COLUMNS FROM `" . str_replace('`', '', $table) . "`") as $r) {
            $cols[] = strtolower((string)($r['Field'] ?? ''));
        }
    } catch (Throwable $e) {
        error_log('[profil_siswa.update] dbCols(' . $table . '): ' . $e->getMessage());
    }
    return $cache[$table] = $cols;
}
function hasCol(PDO $pdo, string $table, string $col): bool {
    return in_array(strtolower($col), dbCols($pdo, $table), true);
}

/* ===== SISWA UPDATE (aksi=update) ===== */
$raw = file_get_contents('php://input');
$input = $raw === false ? [] : json_decode($raw, true);
$input = is_array($input) ? $input : [];

if (strtolower((string)($input['aksi'] ?? '')) === 'update') {
    try {
        $data = isset($input['data']) && is_array($input['data']) ? $input['data'] : [];
        $pdo->beginTransaction();

        /* ---- 1) tabel siswa ---- */
        $siswaCols = [
            'nis','nisn','nama_lengkap','nama_panggilan','jenis_kelamin',
            'tempat_lahir','tanggal_lahir','agama','no_hp','email','nik','no_kk',
            'akta_lahir','anak_ke','jumlah_saudara','golongan_darah',
            'tinggi_badan_saat_masuk','berat_badan_saat_masuk','tinggi_badan',
            'berat_badan','disabilitas','alergi','riwayat_penyakit','pondok',
            'status','status_santri','status_asrama','tanggal_masuk','alamat',
            'rt','rw','desa_kelurahan','kecamatan','provinsi','kode_pos',
            'transportasi','jarak_rumah_ke_sekolah','waktu_perjalanan',
            'no_kip','kip','pkh','hobi','cita_cita',
        ];
        $siswaCols = array_values(array_intersect(
            $siswaCols, dbCols($pdo, 'siswa'))); // hanya kolom yang benar-benar ada
        if (!empty($data['siswa']) && is_array($data['siswa'])) {
            $s = $data['siswa'];
            $set = [];
            $val = [];
            foreach ($siswaCols as $col) {
                $src = $col;
                if ($col === 'kabupaten_kota') continue; // pakai kunci 'kabupaten'
                if (array_key_exists($src, $s) && $s[$src] !== null) {
                    $set[] = "$col = ?";
                    $val[] = $s[$src] === '' ? null : $s[$src];
                }
            }
            if (hasCol($pdo, 'siswa', 'kabupaten_kota')
                && array_key_exists('kabupaten', $s) && $s['kabupaten'] !== null) {
                $set[] = 'kabupaten_kota = ?';
                $val[] = $s['kabupaten'] === '' ? null : $s['kabupaten'];
            }
            if ($set) {
                $val[] = $siswa_id;
                $stmt = $pdo->prepare('UPDATE siswa SET ' . implode(', ', $set) . ' WHERE id = ?');
                $stmt->execute($val);
            }

            /* ---- kategori siswa (tabel opsional; error tidak mematikan simpan) ---- */
            if (array_key_exists('kategori', $s)) {
                try {
                    $kv = ($s['kategori'] === null || $s['kategori'] === '') ? null : $s['kategori'];
                    $row = dbRow($pdo, 'SELECT id FROM siswa_kategori WHERE siswa_id = ? LIMIT 1', [$siswa_id]);
                    if ($row) {
                        $stmt = $pdo->prepare('UPDATE siswa_kategori SET kategori = ? WHERE id = ?');
                        $stmt->execute([$kv, $row['id']]);
                    } elseif ($kv !== null) {
                        $stmt = $pdo->prepare('INSERT INTO siswa_kategori (siswa_id, kategori) VALUES (?, ?)');
                        $stmt->execute([$siswa_id, $kv]);
                    }
                } catch (Throwable $e) {
                    error_log('[profil_siswa.update] kategori: ' . $e->getMessage());
                }
            }

            /* ---- sekolah asal ---- */
            if (!empty($data['sekolah_asal']) && is_array($data['sekolah_asal'])) {
                $sk = $data['sekolah_asal'];
                $r = dbRow($pdo, 'SELECT sekolah_id FROM siswa WHERE id = ? LIMIT 1', [$siswa_id]);
                $sekolahId = !empty($r['sekolah_id']) ? (int)$r['sekolah_id'] : 0;
                $map = ['jenis_sekolah' => 'jenis_sekolah', 'nama_sekolah' => 'nama_sekolah',
                        'npsn' => 'npsn', 'nsm' => 'nsm', 'alamat' => 'alamat_lengkap'];
                $colsReal = dbCols($pdo, 'siswa_sekolah');
                $map = array_filter($map, function ($dbCol) use ($colsReal) {
                    return in_array(strtolower($dbCol), $colsReal, true);
                });
                $set = [];
                $val = [];
                foreach ($map as $src => $col) {
                    if (array_key_exists($src, $sk) && $sk[$src] !== null) {
                        $set[] = "$col = ?";
                        $val[] = $sk[$src] === '' ? null : $sk[$src];
                    }
                }
                if ($set) {
                    if ($sekolahId) {
                        $val[] = $sekolahId;
                        $stmt = $pdo->prepare('UPDATE siswa_sekolah SET ' . implode(', ', $set) . ' WHERE id = ?');
                        $stmt->execute($val);
                    } else {
                        /* INSERT memakai nama kolom DB (bukan kunci payload) */
                        $rels = []; // pasangan (src, dbCol)
                        foreach ($map as $src => $col) {
                            if (array_key_exists($src, $sk)) $rels[] = [$src, $col];
                        }
                        $cols = array_column($rels, 1);
                        $colVal = [];
                        foreach ($rels as $rel) {
                            $v = $sk[$rel[0]] ?? null;
                            $colVal[] = ($v === null || $v === '') ? null : $v;
                        }
                        $stmt = $pdo->prepare('INSERT INTO siswa_sekolah (' . implode(', ', $cols) . ') VALUES (' . implode(', ', array_fill(0, count($cols), '?')) . ')');
                        $stmt->execute($colVal);
                        $newId = (int)$pdo->lastInsertId();
                        $stmt = $pdo->prepare('UPDATE siswa SET sekolah_id = ? WHERE id = ?');
                        $stmt->execute([$newId, $siswa_id]);
                    }
                }
            }

            /* ---- riwayat mutasi (sekolah pindahan) ---- */
            if (!empty($data['mutasi']) && is_array($data['mutasi'])) {
                $mu = $data['mutasi'];
                $map = ['nama_sekolah' => 'nama_sekolah', 'npsn' => 'npsn',
                        'nsm' => 'nsm', 'alamat' => 'alamat'];
                $colsReal = dbCols($pdo, 'siswa_sekolah_pindahan');
                $map = array_filter($map, function ($dbCol) use ($colsReal) {
                    return in_array(strtolower($dbCol), $colsReal, true);
                });
                $set = [];
                $val = [];
                foreach ($map as $src => $col) {
                    if (array_key_exists($src, $mu) && $mu[$src] !== null) {
                        $set[] = "$col = ?";
                        $val[] = $mu[$src] === '' ? null : $mu[$src];
                    }
                }
                if ($set) {
                    $row = dbRow($pdo, 'SELECT id FROM siswa_sekolah_pindahan WHERE siswa_id = ? LIMIT 1', [$siswa_id]);
                    if ($row) {
                        $val[] = $row['id'];
                        $stmt = $pdo->prepare('UPDATE siswa_sekolah_pindahan SET ' . implode(', ', $set) . ' WHERE id = ?');
                        $stmt->execute($val);
                    } else {
                        $rels = [];
                        if (hasCol($pdo, 'siswa_sekolah_pindahan', 'siswa_id')) $rels[] = ['__siswa_id__', 'siswa_id'];
                        foreach ($map as $src => $col) {
                            if (array_key_exists($src, $mu)) $rels[] = [$src, $col];
                        }
                        $cols = array_column($rels, 1);
                        $colVal = [];
                        foreach ($rels as $rel) {
                            if ($rel[0] === '__siswa_id__') { $colVal[] = $siswa_id; continue; }
                            $v = $mu[$rel[0]] ?? null;
                            $colVal[] = ($v === null || $v === '') ? null : $v;
                        }
                        $stmt = $pdo->prepare('INSERT INTO siswa_sekolah_pindahan (' . implode(', ', $cols) . ') VALUES (' . implode(', ', array_fill(0, count($cols), '?')) . ')');
                        $stmt->execute($colVal);
                    }
                }
            }
        }

        /* ---- 2) orang tua (ayah/ibu/wali) ---- */
        if (!empty($data['orangtua']) && is_array($data['orangtua'])) {
            $ortuCols = ['nama','nik','status_hidup','tempat_lahir','tanggal_lahir',
                         'pendidikan','pekerjaan','penghasilan','telepon','alamat',
                         'hubungan'];
            $ortuReal = dbCols($pdo, 'siswa_orangtua');
            $ortuCols = array_values(array_intersect(
                $ortuCols, $ortuReal)); // hanya kolom yang benar-benar ada
            foreach (['ayah','ibu','wali'] as $jenis) {
                $o = isset($data['orangtua'][$jenis]) && is_array($data['orangtua'][$jenis])
                     ? $data['orangtua'][$jenis] : null;
                if ($o === null) continue;

                $set = [];
                $val = [];
                foreach ($ortuCols as $col) {
                    if (!array_key_exists($col, $o)) continue;
                    $v = is_scalar($o[$col]) ? $o[$col] : null;
                    $set[] = "$col = ?";
                    $val[] = ($v === '' || $v === null) ? null : (string)$v;
                }
                if (!$set) continue;

                $row = dbRow($pdo, 'SELECT id FROM siswa_orangtua WHERE siswa_id = ? AND jenis = ? LIMIT 1', [$siswa_id, $jenis]);
                if ($row) {
                    $val[] = $row['id'];
                    $stmt = $pdo->prepare('UPDATE siswa_orangtua SET ' . implode(', ', $set) . ' WHERE id = ?');
                    $stmt->execute($val);
                } else {
                    $colNames = array_merge(['siswa_id','jenis'],
                                            array_map(function ($x) { return explode(' = ', $x)[0]; }, $set));
                    $stmt = $pdo->prepare('INSERT INTO siswa_orangtua (' . implode(', ', $colNames) . ') VALUES (' . implode(', ', array_fill(0, count($colNames), '?')) . ')');
                    $stmt->execute(array_merge([$siswa_id, $jenis], $val));
                }

                /* app mengirim 'alamat' = hasil rangkai (sudah memuat RT/desa/dll.)
                   -> kosongkan komponen lama agar tidak dirangkai dua kali */
                if (array_key_exists('alamat', $o) && in_array('alamat', $ortuReal, true)) {
                    $clearCols = array_values(array_intersect(
                        ['rt','rw','desa','kecamatan','kabupaten','provinsi','kode_pos'],
                        $ortuReal));
                    if ($clearCols) {
                        $stmt = $pdo->prepare('UPDATE siswa_orangtua SET ' .
                            implode(', ', array_map(fn($c) => "$c = NULL", $clearCols)) .
                            ' WHERE siswa_id = ?');
                        $stmt->execute([$siswa_id]);
                    }
                }
            }
        }

        $pdo->commit();
        jsonOut(true, 'Data siswa berhasil disimpan.');
    } catch (\Throwable $e) {
        if ($pdo->inTransaction()) $pdo->rollBack();
        error_log('[profil_siswa.update] ' . $e->getMessage());
        jsonOut(false, 'Gagal menyimpan data: ' . $e->getMessage());
    }
}

try {
    /* ── Data inti siswa + kelas + tahun ajaran/semester ── */
    $ds = dbRow($pdo, "
        SELECT s.*, CONCAT(k.tingkat,'-',k.rombel) AS kelas_label,
               k.nama_kelas, k.tingkat AS kelas_tingkat, k.rombel AS kelas_rombel,
               ta.nama_tahun, sm.nama_semester
        FROM siswa s
        LEFT JOIN kelas k ON s.kelas_id = k.id
        LEFT JOIN tahun_ajaran ta ON s.tahun_ajaran_id = ta.id
        LEFT JOIN semester sm ON s.semester_id = sm.id
        WHERE s.id = ? LIMIT 1
    ", [$siswa_id]);

    if (!$ds) {
        jsonOut(false, 'Data siswa tidak ditemukan.', [], 404);
    }

    /* ── Sekolah asal ── */
    $dSekolah = !empty($ds['sekolah_id'])
        ? dbRow($pdo, "SELECT * FROM siswa_sekolah WHERE id = ? LIMIT 1", [$ds['sekolah_id']])
        : [];

    /* ── Sekolah asal sebelum mutasi (kalau ada, tabel opsional) ── */
    $dMutasi = [];
    try {
        $dMutasi = dbRow($pdo, "SELECT * FROM siswa_sekolah_pindahan WHERE siswa_id = ? LIMIT 1", [$siswa_id]);
    } catch (Throwable $e) {
        $dMutasi = [];
    }

    /* ── Orang tua / wali ── */
    $dAyah = dbRow($pdo, "SELECT * FROM siswa_orangtua WHERE siswa_id = ? AND jenis = 'ayah' LIMIT 1", [$siswa_id]);
    $dIbu  = dbRow($pdo, "SELECT * FROM siswa_orangtua WHERE siswa_id = ? AND jenis = 'ibu'  LIMIT 1", [$siswa_id]);
    $dWali = dbRow($pdo, "SELECT * FROM siswa_orangtua WHERE siswa_id = ? AND jenis = 'wali' LIMIT 1", [$siswa_id]);

    /* ── Kategori siswa (tabel opsional) ── */
    $dKategori = [];
    try {
        $dKategori = dbRow($pdo, "SELECT * FROM siswa_kategori WHERE siswa_id = ? LIMIT 1", [$siswa_id]);
    } catch (Throwable $e) {
        $dKategori = [];
    }

    /* ── Lampiran dokumen ── */
    $dLamp = dbRow($pdo, "SELECT * FROM lampiran_siswa WHERE siswa_id = ? LIMIT 1", [$siswa_id]);
    $lampiranMap = [
        'file_foto'       => 'Foto Siswa',
        'file_kk'         => 'Kartu Keluarga',
        'file_akta'       => 'Akta Lahir',
        'file_ijazah'     => 'Ijazah',
        'file_skl'        => 'SKL',
        'file_ktp_ayah'   => 'KTP Ayah',
        'file_ktp_ibu'    => 'KTP Ibu',
        'file_ktp_wali'   => 'KTP Wali',
        'file_kip'        => 'KIP',
        'file_rapor_asal' => 'Rapor Asal',
        'file_lain1'      => 'Lampiran Lain 1',
        'file_lain2'      => 'Lampiran Lain 2',
        'file_lain3'      => 'Lampiran Lain 3',
    ];
    $lampiranOut = [];
    foreach ($lampiranMap as $field => $label) {
        $lampiranOut[] = [
            'field' => $field,
            'label' => $label,
            'tersedia' => !empty($dLamp[$field]),
            'url' => $dLamp[$field] ?? null,
        ];
    }

    /* ── Riwayat kelas ── */
    $riwayat = dbRows($pdo, "
        SELECT rs.status, rs.tanggal_masuk, rs.tanggal_keluar, k.nama_kelas, k.tingkat, k.rombel,
               ta.nama_tahun, sm.nama_semester
        FROM riwayat_siswa rs
        LEFT JOIN kelas k ON rs.kelas_id = k.id
        LEFT JOIN tahun_ajaran ta ON rs.tahun_ajaran_id = ta.id
        LEFT JOIN semester sm ON rs.semester_id = sm.id
        WHERE rs.siswa_id = ?
        ORDER BY rs.tanggal_masuk DESC, rs.id DESC
    ", [$siswa_id]);

    /* ── Rangkai alamat siswa jadi satu string ── */
    $alamatParts = array_filter([
        $ds['alamat'] ?? '',
        (($ds['rt'] ?? '') && ($ds['rw'] ?? '')) ? 'RT ' . $ds['rt'] . '/RW ' . $ds['rw'] : '',
        $ds['desa_kelurahan'] ?? '',
        $ds['kecamatan'] ?? '',
        $ds['kabupaten_kota'] ?? '',
        $ds['provinsi'] ?? '',
        $ds['kode_pos'] ?? '',
    ]);

    /* ── Helper rangkai alamat orang tua/wali ── */
    $rangkaiAlamatOrtu = function (array $d): string {
        if (empty($d)) return '';
        $parts = array_filter([
            $d['alamat'] ?? '',
            (($d['rt'] ?? '') && ($d['rw'] ?? '')) ? 'RT ' . $d['rt'] . '/RW ' . $d['rw'] : '',
            $d['desa'] ?? '',
            $d['kecamatan'] ?? '',
            $d['kabupaten'] ?? '',
            $d['provinsi'] ?? '',
            $d['kode_pos'] ?? '',
        ]);
        return implode(', ', $parts);
    };

    $formatOrtu = function (array $d) use ($rangkaiAlamatOrtu): ?array {
        if (empty($d)) return null;
        return [
            'nama' => nz($d['nama'] ?? null, null),
            'nik' => nz($d['nik'] ?? null, null),
            'status_hidup' => nz($d['status_hidup'] ?? null, null),
            'tempat_lahir' => nz($d['tempat_lahir'] ?? null, null),
            'tanggal_lahir' => nz($d['tanggal_lahir'] ?? null, null),
            'pendidikan' => nz($d['pendidikan'] ?? null, null),
            'pekerjaan' => nz($d['pekerjaan'] ?? null, null),
            'penghasilan' => nz($d['penghasilan'] ?? null, null),
            'telepon' => nz($d['telepon'] ?? null, null),
            'alamat' => $rangkaiAlamatOrtu($d) ?: null,
            'hubungan' => nz($d['hubungan'] ?? null, null), // khusus wali
        ];
    };

    jsonOut(true, 'Data profil ditemukan.', [
        'siswa' => [
            'id' => (int)$ds['id'],
            'nis' => nz($ds['nis'] ?? null, null),
            'nisn' => nz($ds['nisn'] ?? null, null),
            'nama_lengkap' => nz($ds['nama_lengkap'] ?? null, null),
            'nama_panggilan' => nz($ds['nama_panggilan'] ?? null, null),
            'jenis_kelamin' => nz($ds['jenis_kelamin'] ?? null, null),
            'tempat_lahir' => nz($ds['tempat_lahir'] ?? null, null),
            'tanggal_lahir' => nz($ds['tanggal_lahir'] ?? null, null),
            'agama' => nz($ds['agama'] ?? null, null),
            'no_hp' => nz($ds['no_hp'] ?? null, null),
            'email' => nz($ds['email'] ?? null, null),
            'nik' => nz($ds['nik'] ?? null, null),
            'no_kk' => nz($ds['no_kk'] ?? null, null),
            'akta_lahir' => nz($ds['akta_lahir'] ?? null, null),
            'anak_ke' => nz($ds['anak_ke'] ?? null, null),
            'jumlah_saudara' => nz($ds['jumlah_saudara'] ?? null, null),
            'golongan_darah' => nz($ds['golongan_darah'] ?? null, null),
            'tinggi_badan_saat_masuk' => nz($ds['tinggi_badan_saat_masuk'] ?? null, null),
            'berat_badan_saat_masuk' => nz($ds['berat_badan_saat_masuk'] ?? null, null),
            'tinggi_badan' => nz($ds['tinggi_badan'] ?? null, null),
            'berat_badan' => nz($ds['berat_badan'] ?? null, null),
            'disabilitas' => nz($ds['disabilitas'] ?? null, null),
            'alergi' => nz($ds['alergi'] ?? null, null),
            'riwayat_penyakit' => nz($ds['riwayat_penyakit'] ?? null, null),
            'pondok' => nz($ds['pondok'] ?? null, null),
            'status' => nz($ds['status'] ?? null, 'Aktif'),
            'status_santri' => nz($ds['status_santri'] ?? null, null),
            'status_asrama' => nz($ds['status_asrama'] ?? null, null),
            'tanggal_masuk' => nz($ds['tanggal_masuk'] ?? null, null),
            'tanggal_daftar' => nz($ds['created_at'] ?? null, null),
            'kategori' => nz($dKategori['kategori'] ?? null, null),
            'kelas' => nz($ds['kelas_label'] ?? $ds['nama_kelas'] ?? null, null),
            'tingkat' => nz($ds['kelas_tingkat'] ?? null, null),
            'tahun_ajaran' => nz($ds['nama_tahun'] ?? null, null),
            'semester' => nz($ds['nama_semester'] ?? null, null),
            'alamat' => $alamatParts ? implode(', ', $alamatParts) : null,
            'alamat_raw' => nz($ds['alamat'] ?? null, null),
            'rt' => nz($ds['rt'] ?? null, null),
            'rw' => nz($ds['rw'] ?? null, null),
            'desa_kelurahan' => nz($ds['desa_kelurahan'] ?? null, null),
            'kecamatan' => nz($ds['kecamatan'] ?? null, null),
            'kabupaten' => nz($ds['kabupaten_kota'] ?? null, null),
            'provinsi' => nz($ds['provinsi'] ?? null, null),
            'kode_pos' => nz($ds['kode_pos'] ?? null, null),
            'transportasi' => nz($ds['transportasi'] ?? null, null),
            'jarak_rumah_ke_sekolah' => nz($ds['jarak_rumah_ke_sekolah'] ?? null, null),
            'waktu_perjalanan' => nz($ds['waktu_perjalanan'] ?? null, null),
            'no_kip' => nz($ds['no_kip'] ?? null, null),
            'kip' => nz($ds['kip'] ?? null, null),
            'pkh' => nz($ds['pkh'] ?? null, null),
            'hobi' => nz($ds['hobi'] ?? null, null),
            'cita_cita' => nz($ds['cita_cita'] ?? null, null),
            'foto_url' => nz($dLamp['file_foto'] ?? null, null),
        ],
        'sekolah_asal' => !empty($dSekolah) ? [
            'jenis_sekolah' => nz($dSekolah['jenis_sekolah'] ?? null, null),
            'nama_sekolah' => nz($dSekolah['nama_sekolah'] ?? null, null),
            'npsn' => nz($dSekolah['npsn'] ?? null, null),
            'nsm' => nz($dSekolah['nsm'] ?? null, null),
            'alamat' => nz($dSekolah['alamat_lengkap'] ?? null, null),
        ] : null,
        'mutasi' => !empty($dMutasi) ? [
            'nama_sekolah' => nz($dMutasi['nama_sekolah'] ?? null, null),
            'npsn' => nz($dMutasi['npsn'] ?? null, null),
            'nsm' => nz($dMutasi['nsm'] ?? null, null),
            'alamat' => nz($dMutasi['alamat'] ?? null, null),
        ] : null,
        'orangtua' => [
            'ayah' => $formatOrtu($dAyah),
            'ibu' => $formatOrtu($dIbu),
            'wali' => $formatOrtu($dWali),
        ],
        'lampiran' => $lampiranOut,
        'riwayat_kelas' => array_map(function ($r) {
            return [
                'status' => nz($r['status'] ?? null, null),
                'tanggal_masuk' => nz($r['tanggal_masuk'] ?? null, null),
                'tanggal_keluar' => nz($r['tanggal_keluar'] ?? null, null),
                'kelas' => !empty($r['nama_kelas']) || !empty($r['tingkat'])
                    ? trim(($r['tingkat'] ?? '') . '.' . ($r['rombel'] ?? ''), '.')
                    : null,
                'tahun_ajaran' => nz($r['nama_tahun'] ?? null, null),
                'semester' => nz($r['nama_semester'] ?? null, null),
            ];
        }, $riwayat),
    ]);

} catch (Throwable $e) {
    error_log('[profil-siswa-api] Error: ' . $e->getMessage());
    jsonOut(false, 'Terjadi kesalahan server.', [], 500);
}