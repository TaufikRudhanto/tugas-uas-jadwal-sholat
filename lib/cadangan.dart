import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:lat_lng_to_timezone/lat_lng_to_timezone.dart' as tzmap;

class Cadangan extends StatefulWidget {
  const Cadangan({super.key});

  @override
  State<Cadangan> createState() => _CadanganState();
}

class _CadanganState extends State<Cadangan> {
  List<Map<String, String>> prayerTimesList = [];

  @override
  void initState() {
    super.initState();
    getPrayerTimes();
  }

  void getPrayerTimes() async {
    LocationPermission permission;
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
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

    DateTime now = tz.TZDateTime.from(DateTime.now(), location);
    Coordinates coordinates = Coordinates(latitude, longitude);
    CalculationParameters params = CalculationMethod.singapore();
    params.madhab = Madhab.shafi;

    List<Map<String, String>> tempList = [];

    for (int i = 0; i < 30; i++) {
      DateTime date = now.add(Duration(days: i));
      PrayerTimes prayerTimes = PrayerTimes(
          date: date, coordinates: coordinates, calculationParameters: params);

      tempList.add({
        'date': DateFormat('d MMM yyyy').format(date),
        'Imsak': DateFormat('HH:mm').format(tz.TZDateTime.from(
            prayerTimes.fajr!.subtract(const Duration(minutes: 10)), location)),
        'Subuh': DateFormat('HH:mm')
            .format(tz.TZDateTime.from(prayerTimes.fajr!, location)),
        'Terbit': DateFormat('HH:mm')
            .format(tz.TZDateTime.from(prayerTimes.sunrise!, location)),
        'Dzuhur': DateFormat('HH:mm')
            .format(tz.TZDateTime.from(prayerTimes.dhuhr!, location)),
        'Ashar': DateFormat('HH:mm')
            .format(tz.TZDateTime.from(prayerTimes.asr!, location)),
        'Maghrib': DateFormat('HH:mm')
            .format(tz.TZDateTime.from(prayerTimes.maghrib!, location)),
        'Isya': DateFormat('HH:mm')
            .format(tz.TZDateTime.from(prayerTimes.isha!, location)),
      });
    }

    setState(() {
      prayerTimesList = tempList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          color: const Color.fromARGB(255, 47, 144, 139),
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                DataTable(
                  columns: const [
                    DataColumn(label: Text('Tanggal')),
                    DataColumn(label: Text('Imsak')),
                    DataColumn(label: Text('Subuh')),
                    DataColumn(label: Text('Terbit')),
                    DataColumn(label: Text('Dzuhur')),
                    DataColumn(label: Text('Ashar')),
                    DataColumn(label: Text('Maghrib')),
                    DataColumn(label: Text('Isya')),
                  ],
                  rows: prayerTimesList.map((time) {
                    return DataRow(
                      cells: [
                        DataCell(Text(time['date']!)),
                        DataCell(Text(time['Imsak']!)),
                        DataCell(Text(time['Subuh']!)),
                        DataCell(Text(time['Terbit']!)),
                        DataCell(Text(time['Dzuhur']!)),
                        DataCell(Text(time['Ashar']!)),
                        DataCell(Text(time['Maghrib']!)),
                        DataCell(Text(time['Isya']!)),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
