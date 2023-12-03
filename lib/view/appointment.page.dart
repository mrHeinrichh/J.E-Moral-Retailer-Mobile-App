import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:retailer_app/widgets/custom_button.dart';
import 'package:retailer_app/widgets/date_time_picker.dart';
import 'package:provider/provider.dart';
import 'package:retailer_app/view/user_provider.dart';

class AppointmentPage extends StatefulWidget {
  @override
  _AppointmentPageState createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  DateTime? selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  TextEditingController dateController = TextEditingController();
  TextEditingController timeController = TextEditingController();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        dateController.text = '${picked.toLocal()}'.split(' ')[0];
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null) {
      setState(() {
        selectedTime = picked;
        timeController.text = picked.format(context);
      });
    }
  }

  Future<void> _updateAppointment() async {
    String? userId = Provider.of<UserProvider>(context, listen: false).userId;

    if (userId != null && selectedDate != null) {
      final apiUrl = 'https://lpg-api-06n8.onrender.com/api/v1/users/$userId';

      final patchData = {
        "dateInterview": dateController.text,
        "timeInterview": timeController.text,
        "hasAppointment": "true",
        "type": "retailer"
      };

      print('Request body: ${jsonEncode(patchData)}'); // Log the request body

      try {
        final response = await http.patch(
          Uri.parse(apiUrl),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode(patchData),
        );

        print('Response body: ${response.body}'); // Log the response body

        if (response.statusCode == 200) {
          print(response.statusCode);
          print('Appointment updated successfully');
        } else {
          print(
              'Failed to update appointment. Status code: ${response.statusCode}');
        }
      } catch (e) {
        print('Error updating appointment: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String? userId = Provider.of<UserProvider>(context).userId;

    print('UserId in build method: $userId');

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        title: const Padding(
          padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
          child: Text(
            'Applying for a Rider',
            style: TextStyle(color: Color(0xFF232937), fontSize: 24),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 60, 5, 5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Must have...',
                  style: TextStyle(fontSize: 20),
                ),
                SizedBox(height: 20),
                Text(
                  '*BioData',
                  style: TextStyle(fontSize: 20),
                ),
                Text(
                  '*Drivers License ',
                  style: TextStyle(fontSize: 20),
                ),
                Text(
                  '*NBI Clearance(if available) ',
                  style: TextStyle(fontSize: 20),
                ),
                Text(
                  '*Fire Safety Certification ',
                  style: TextStyle(fontSize: 20),
                ),
                Text(
                  '*Verified Maya/Gcash ',
                  style: TextStyle(fontSize: 20),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(children: [
              DateTimePicker(
                dateController: dateController,
                timeController: timeController,
                onDateTap: () => _selectDate(context),
                onTimeTap: () => _selectTime(context),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: CustomizedButton(
                  onPressed: _updateAppointment,
                  text: 'Book an Appointment',
                  height: 60,
                  width: 90,
                  fontz: 20,
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
