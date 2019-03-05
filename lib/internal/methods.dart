import 'package:android_flutter_updater/android_flutter_updater.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_data.dart';

void triggerCallbacks(dynamic nativeMap, {bool force = false}) {
  AppData().setStateCallbacks.forEach((key, data) {
    if (data[1] || force || strToBool(nativeMap['force_update_ui']))
      AndroidFlutterUpdater.getDownloads().then((v) => data[0](() {
            AppData().nativeData = nativeMap;
            AppData().updateIds = v;
          }));
  });
}

void registerCallback(Key k, Function cb, {bool critical = false}) {
  dynamic data = [cb, critical];
  AppData().setStateCallbacks[k] = data;
}

void unregisterCallback(Key k) {
  AppData().setStateCallbacks.remove(k);
}

dynamic strToStatusEnum(String value) {
  return UpdateStatus.values.firstWhere(
      (e) => e.toString().split('.')[1].toUpperCase() == value.toUpperCase());
}

bool strToBool(String ip) {
  return ip == null ? false : ip.toLowerCase() == "true";
}

String filterPercentage(String ip) {
  return ip.replaceAll(new RegExp(r'%'), '');
}

String statusCapitalize(String s) {
  s = s.split('.')[1];
  s = strToStatusEnum(s) == UpdateStatus.PAUSED_ERROR ? "cancelled" : s;
  return (s[0].toUpperCase() + s.toLowerCase().substring(1))
      .replaceAll(new RegExp(r'_'), ' ');
}

bool statusEnumCheck(UpdateStatus u) {
  return strToStatusEnum(AppData().nativeData['update_status']) == u;
}

int totalSizeInMb() {
  return int.parse(AppData().nativeData['size']) ~/ (1024 * 1024);
}

int totalCompletedInMb() {
  return ((int.parse(AppData().nativeData['size']) ~/ (1024 * 1024)) *
          (int.parse(filterPercentage(AppData().nativeData['percentage'])) /
              100))
      .toInt();
}

void launchUrl(String url) async {
  if (await canLaunch(url))
    await launch(url);
  else
    throw 'Could not launch $url!';
}

Future<void> handleAdvancedMode() async {
  bool advancedModeEnabled = await getAdvancedMode();
  if (!advancedModeEnabled) {
    // Advanced mode not enabled
    // Check and set
    if (++AppData().advancedMode >= 10) {
      triggerCallbacks(AppData().nativeData, force: true);
      setAdvancedMode(true);
    }
  } else {
    // Advanced mode enabled
    // This means app has just started
    if (AppData().advancedMode < 10) triggerCallbacks(AppData().nativeData);
  }
}

Future<bool> getAdvancedMode() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getBool('advanced_mode') ?? false;
}

Future<void> setAdvancedMode(bool enable) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setBool('advanced_mode', enable);
}

Future<bool> getLightTheme() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getBool('light_theme') ?? false;
}

Future<void> setLightTheme(bool light) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setBool('light_theme', light);
  AppData().setLight(light);
}
