import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher_string.dart';

class HelperFunctions{
  HelperFunctions._();

  // -- Check Dark Mode
  static bool isDarkMode(BuildContext context){
    return Theme.of(context).brightness == Brightness.dark;
  }

  // -- Set status bar color
  static Future<void> setStatusBarColor({required Color color}) async{
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(statusBarColor: color),
    );
  }

  // -- Launch URL
  static void launchURL(String url) async{
    if(await canLaunchUrlString(url)){
      await launchUrlString(url);
    }else{
      throw "Could not launch URL: $url";
    }
  }
}