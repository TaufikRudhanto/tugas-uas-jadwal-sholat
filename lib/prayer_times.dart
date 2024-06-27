import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:adhan_dart/adhan_dart.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:lat_lng_to_timezone/lat_lng_to_timezone.dart' as tzmap;
import 'package:hijri/hijri_calendar.dart';
import 'package:cobaaja/compass_page.dart';
import 'package:cobaaja/calendar_screen.dart';
import 'package:intl/date_symbol_data_local.dart';

class PrayerTimes2 extends StatefulWidget {
  const PrayerTimes2({super.key});

  @override
  State<PrayerTimes2> createState() => _PrayerTimes2State();
}

class _PrayerTimes2State extends State<PrayerTimes2> {
  // ignore: non_constant_identifier_names
  String Imsak = '';
  // ignore: non_constant_identifier_names
  String Subuh = '';
  // ignore: non_constant_identifier_names
  String Terbit = '';
  // ignore: non_constant_identifier_names
  String Dzuhur = '';
  // ignore: non_constant_identifier_names
  String Ashar = '';
  // ignore: non_constant_identifier_names
  String Maghrib = '';
  // ignore: non_constant_identifier_names
  String Isya = '';
  String _gregorianDate = 'Loading...';
  String _hijriDate = 'Loading...';
  String _location = 'Loading...';
  String _fullLocation = 'Loading...';

  @override
  void initState() {
    super.initState();
    getPrayerTimes();
    _setDates();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    Position position = await Geolocator.getCurrentPosition();
    List<Placemark> placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);

    if (placemarks.isNotEmpty) {
      Placemark placemark = placemarks.first;
      setState(() {
        _location = placemark.subLocality ?? 'Unknown Location';
        _fullLocation =
            '${placemark.locality}, ${placemark.administrativeArea}, ${placemark.country}';
      });
    }
  }

  void _setDates() async {
    await initializeDateFormatting('id_ID', '');

    DateTime now = DateTime.now();
    HijriCalendar hijriCalendar = HijriCalendar.now();
    HijriCalendar.setLocal("id");

    setState(() {
      _gregorianDate = DateFormat('d MMMM yyyy', 'id_ID').format(now);
      _hijriDate =
          "${hijriCalendar.hDay} ${hijriCalendar.longMonthName} ${hijriCalendar.hYear}";
    });
  }

  void getPrayerTimes() async {
    LocationPermission permission;
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      // Handle the case where the user denies the location permission.
      if (kDebugMode) {
        print("Location permission denied");
      }
      return;
    }
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    double latitude = position.latitude;
    double longitude = position.longitude;
    if (kDebugMode) {
      print(latitude);
    }
    if (kDebugMode) {
      print(longitude);
    }

    tz.initializeTimeZones();
    String tzs = tzmap.latLngToTimezoneString(latitude, longitude);
    if (kDebugMode) {
      print(tzs);
    }
    final location = tz.getLocation(tzs);

    DateTime date = tz.TZDateTime.from(DateTime.now(), location);
    Coordinates coordinates = Coordinates(latitude, longitude);

    CalculationParameters params = CalculationMethod.singapore();
    params.madhab = Madhab.shafi;
    PrayerTimes prayerTimes = PrayerTimes(
        date: date, coordinates: coordinates, calculationParameters: params);

    setState(() {
      Imsak = DateFormat('HH:mm')
          .format(tz.TZDateTime.from(
              prayerTimes.fajr!.subtract(const Duration(minutes: 10)),
              location))
          .toString();
      Subuh = DateFormat('HH:mm')
          .format(tz.TZDateTime.from(prayerTimes.fajr!, location))
          .toString();
      Terbit = DateFormat('HH:mm')
          .format(tz.TZDateTime.from(prayerTimes.sunrise!, location))
          .toString();
      Dzuhur = DateFormat('HH:mm')
          .format(tz.TZDateTime.from(prayerTimes.dhuhr!, location))
          .toString();
      Ashar = DateFormat('HH:mm')
          .format(tz.TZDateTime.from(prayerTimes.asr!, location))
          .toString();
      Maghrib = DateFormat('HH:mm')
          .format(tz.TZDateTime.from(prayerTimes.maghrib!, location))
          .toString();
      Isya = DateFormat('HH:mm')
          .format(tz.TZDateTime.from(prayerTimes.isha!, location))
          .toString();
    });

    if (kDebugMode) {
      print("Imsak: $Imsak");
    }
    if (kDebugMode) {
      print("Subuh: $Subuh");
    }
    if (kDebugMode) {
      print("Terbit: $Terbit");
    }
    if (kDebugMode) {
      print("Dzuhur: $Dzuhur");
    }
    if (kDebugMode) {
      print("Ashar: $Ashar");
    }
    if (kDebugMode) {
      print("Maghrib: $Maghrib");
    }
    if (kDebugMode) {
      print("Isya: $Isya");
    }
  }

  List<bool> notificationEnabled = List.generate(7, (_) => false);

  void _showNotificationSettingDialog(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Atur Notifikasi Sholat"),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                ListTile(
                  title: const Text('Suara Adzan'),
                  onTap: () {
                    setState(() {
                      notificationEnabled[index] = true;
                    });
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: const Text('Suara Alarm'),
                  onTap: () {
                    setState(() {
                      notificationEnabled[index] = true;
                    });
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: const Text('Suara Notifikasi'),
                  onTap: () {
                    setState(() {
                      notificationEnabled[index] = true;
                    });
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: const Text('Tanpa Suara'),
                  onTap: () {
                    setState(() {
                      notificationEnabled[index] = true;
                    });
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: const Text('Nonaktif'),
                  onTap: () {
                    setState(() {
                      notificationEnabled[index] = false;
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showLocationOptionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pilih Lokasi'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.location_on),
                  title: const Text('Otomatis (Lokasi Saat Ini)'),
                  onTap: () {
                    // Logika untuk memilih lokasi otomatis
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.map),
                  title: const Text('Manual (Gunakan Peta)'),
                  onTap: () {
                    // Logika untuk memilih lokasi manual
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> cardData = [
      {'title': 'Imsak', 'time': Imsak},
      {'title': 'Subuh', 'time': Subuh},
      {'title': 'Terbit', 'time': Terbit},
      {'title': 'Dzuhur', 'time': Dzuhur},
      {'title': 'Ashar', 'time': Ashar},
      {'title': 'Maghrib', 'time': Maghrib},
      {'title': 'Isya', 'time': Isya},
    ];
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/wd.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        margin: const EdgeInsets.only(top: 25),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _location, // Menambahkan pengecekan null
                  style: GoogleFonts.montserrat(
                    color: const Color.fromARGB(255, 247, 246, 245),
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const CompassPage()),
                    );
                  },
                  child: Icon(
                    MdiIcons.compass,
                    color: const Color.fromARGB(255, 253, 253, 253),
                  ),
                ),
                const SizedBox(width: 10),
                Align(
                  alignment: Alignment.center,
                  child: InkWell(
                    onTap: () {
                      _showLocationOptionsDialog(context);
                    },
                    child: Icon(
                      MdiIcons.mapMarker,
                      color: const Color.fromARGB(255, 253, 253, 253),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  MdiIcons.cog,
                  color: const Color.fromARGB(255, 253, 253, 253),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Text(
                    'Sebentar Lagi Waktu Magrib',
                    style: GoogleFonts.montserrat(
                      color: const Color.fromARGB(255, 247, 246, 245),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '+1 Menit Lagi',
                    style: GoogleFonts.poppins(
                      color: const Color.fromARGB(255, 255, 255, 255),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _hijriDate, // Menambahkan pengecekan null
                  style: GoogleFonts.montserrat(
                    color: const Color.fromARGB(255, 255, 255, 255),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(
                        MdiIcons.calendarRangeOutline,
                        color: const Color.fromARGB(255, 255, 255, 255),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CalendarScreen(),
                          ),
                        );
                      },
                    ),
                    Text(
                      _gregorianDate, // Menambahkan pengecekan null
                      style: GoogleFonts.montserrat(
                        color: const Color.fromARGB(255, 255, 255, 255),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  MdiIcons.accountCircle,
                  color: const Color.fromARGB(255, 255, 255, 255),
                  size: 15,
                ),
                const SizedBox(width: 4),
                Text(
                  _fullLocation,
                  style: GoogleFonts.poppins(
                    color: const Color.fromARGB(255, 255, 255, 255),
                    fontWeight: FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                itemCount: cardData.length,
                itemBuilder: (context, index) {
                  return Column(
                    children: [
                      Card(
                        color: const Color.fromARGB(0, 75, 75, 75)
                            .withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Text(
                                cardData[index]['title']!,
                                style: GoogleFonts.poppins(
                                  color:
                                      const Color.fromARGB(255, 255, 255, 255),
                                  fontSize: 16,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                cardData[index]['time']!,
                                style: GoogleFonts.poppins(
                                  color:
                                      const Color.fromARGB(255, 255, 255, 255),
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              IconButton(
                                icon: notificationEnabled[index]
                                    ? Icon(
                                        MdiIcons.alarmCheck,
                                        color: const Color.fromARGB(
                                            167, 57, 153, 89),
                                        size: 30,
                                      )
                                    : Icon(
                                        MdiIcons.alarmOff,
                                        color: Colors.grey,
                                        size: 30,
                                      ),
                                onPressed: () {
                                  setState(() {
                                    notificationEnabled[index] =
                                        !notificationEnabled[index];
                                    if (notificationEnabled[index]) {
                                      _showNotificationSettingDialog(
                                          context, index);
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
