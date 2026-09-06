/// Respons `app/api/apk/siswa/public_profil` — profil publik madrasah.
/// Kontrak JSON mengikuti aplikasi SIM Siswa versi lama.
class ProfilResponse {
  final bool ok;
  final String message;
  final Profil? profil;
  final Statistik? statistik;

  ProfilResponse({required this.ok, required this.message, this.profil, this.statistik});

  factory ProfilResponse.fromJson(Map<String, dynamic> json) {
    return ProfilResponse(
      ok: json['ok'] == true,
      message: json['message']?.toString() ?? '',
      profil: json['profil'] == null
          ? null
          : Profil.fromJson(json['profil'] as Map<String, dynamic>),
      statistik: json['statistik'] == null
          ? null
          : Statistik.fromJson(json['statistik'] as Map<String, dynamic>),
    );
  }
}

class Profil {
  final String namaMadrasah;
  final String namaSingkat;
  final String npsn;
  final String nsm;
  final String statusMadrasah;
  final String bentukPendidikan;
  final String jenjang;
  final String akreditasi;
  final String tahunBerdiri;
  final String slogan;
  final String namaKepala;
  final String namaYayasan;
  final String ketuaYayasan;
  final String alamat;
  final String desaKelurahan;
  final String kecamatan;
  final String kabupaten;
  final String provinsi;
  final String kodePos;
  final String telepon;
  final String whatsapp;
  final String email;
  final String websiteResmi;
  final String instagram;
  final String facebook;
  final String youtube;
  final String tiktok;
  final String twitter;
  final String visi;
  final String misi;
  final String tujuan;
  final String sejarah;
  final String namaKurikulum;

  Profil({
    required this.namaMadrasah,
    required this.namaSingkat,
    required this.npsn,
    required this.nsm,
    required this.statusMadrasah,
    required this.bentukPendidikan,
    required this.jenjang,
    required this.akreditasi,
    required this.tahunBerdiri,
    required this.slogan,
    required this.namaKepala,
    required this.namaYayasan,
    required this.ketuaYayasan,
    required this.alamat,
    required this.desaKelurahan,
    required this.kecamatan,
    required this.kabupaten,
    required this.provinsi,
    required this.kodePos,
    required this.telepon,
    required this.whatsapp,
    required this.email,
    required this.websiteResmi,
    required this.instagram,
    required this.facebook,
    required this.youtube,
    required this.tiktok,
    required this.twitter,
    required this.visi,
    required this.misi,
    required this.tujuan,
    required this.sejarah,
    required this.namaKurikulum,
  });

  factory Profil.fromJson(Map<String, dynamic> j) {
    String s(dynamic v) => v?.toString() ?? '';
    return Profil(
      namaMadrasah: s(j['nama_madrasah']),
      namaSingkat: s(j['nama_singkat']),
      npsn: s(j['npsn']),
      nsm: s(j['nsm']),
      statusMadrasah: s(j['status_madrasah']),
      bentukPendidikan: s(j['bentuk_pendidikan']),
      jenjang: s(j['jenjang']),
      akreditasi: s(j['akreditasi']),
      tahunBerdiri: s(j['tahun_berdiri']),
      slogan: s(j['slogan']),
      namaKepala: s(j['nama_kepala']),
      namaYayasan: s(j['nama_yayasan']),
      ketuaYayasan: s(j['ketua_yayasan']),
      alamat: s(j['alamat']),
      desaKelurahan: s(j['desa_kelurahan']),
      kecamatan: s(j['kecamatan']),
      kabupaten: s(j['kabupaten']),
      provinsi: s(j['provinsi']),
      kodePos: s(j['kode_pos']),
      telepon: s(j['telepon']),
      whatsapp: s(j['whatsapp']),
      email: s(j['email']),
      websiteResmi: s(j['website_resmi']),
      instagram: s(j['instagram']),
      facebook: s(j['facebook']),
      youtube: s(j['youtube']),
      tiktok: s(j['tiktok']),
      twitter: s(j['twitter']),
      visi: s(j['visi']),
      misi: s(j['misi']),
      tujuan: s(j['tujuan']),
      sejarah: s(j['sejarah']),
      namaKurikulum: s(j['nama_kurikulum']),
    );
  }
}

class Statistik {
  final String tahunAjaran;
  final String semester;
  final int totalSiswa;
  final int siswaL;
  final int siswaP;
  final int jumlahRombel;
  final int jumlahGuru;
  final int jumlahTendik;

  Statistik({
    required this.tahunAjaran,
    required this.semester,
    required this.totalSiswa,
    required this.siswaL,
    required this.siswaP,
    required this.jumlahRombel,
    required this.jumlahGuru,
    required this.jumlahTendik,
  });

  factory Statistik.fromJson(Map<String, dynamic> j) {
    int n(dynamic v) => (v as num?)?.toInt() ?? 0;
    return Statistik(
      tahunAjaran: j['tahun_ajaran']?.toString() ?? '',
      semester: j['semester']?.toString() ?? '',
      totalSiswa: n(j['total_siswa']),
      siswaL: n(j['siswa_l']),
      siswaP: n(j['siswa_p']),
      jumlahRombel: n(j['jumlah_rombel']),
      jumlahGuru: n(j['jumlah_guru']),
      jumlahTendik: n(j['jumlah_tendik']),
    );
  }
}