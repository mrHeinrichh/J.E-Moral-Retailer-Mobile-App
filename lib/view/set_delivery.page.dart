import 'package:retailer_app/routes/app_routes.dart';
import 'package:retailer_app/view/cart_provider.dart';
import 'package:retailer_app/view/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:retailer_app/widgets/custom_button.dart';
import 'package:retailer_app/widgets/custom_timepicker.dart';
import 'package:retailer_app/widgets/location_button.dart';
import 'package:retailer_app/widgets/location_search.dart';
import 'package:retailer_app/widgets/text_field.dart';
import 'package:provider/provider.dart';

class SetDeliveryPage extends StatefulWidget {
  @override
  _SetDeliveryPageState createState() => _SetDeliveryPageState();
}

DateTime? selectedDateTime;

enum PaymentMethod { cashOnDelivery, gcashPayment }

enum AssemblyOption { yes, no }

class _SetDeliveryPageState extends State<SetDeliveryPage> {
  String? selectedLocation;
  PaymentMethod? selectedPaymentMethod;
  AssemblyOption? selectedAssemblyOption;
  List<String> searchResults = [];
  TextEditingController locationController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController contactNumberController = TextEditingController();
  TextEditingController houseNumberController = TextEditingController();

  List<Map<String, dynamic>> convertCartItems(List<CartItem> cartItems) {
    List<Map<String, dynamic>> itemsList = [];
    for (var cartItem in cartItems) {
      if (cartItem.isSelected) {
        itemsList.add({
          "productId":
              cartItem.name, // Use the name as a placeholder for the product ID
          "quantity": cartItem.quantity,
        });
      }
    }
    return itemsList;
  }

  Future<void> fetchLocationData(String query) async {
    if (query.isEmpty) {
      setState(() {
        searchResults = [];
      });
      return;
    }
    const apiKey = 'e8d77b2d8e7740c3b7727970dc8fc59e';
    final apiUrl =
        'https://api.geoapify.com/v1/geocode/autocomplete?text=$query&apiKey=$apiKey';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data.containsKey('features')) {
          final features = data['features'] as List<dynamic>;
          final results = features
              .map((feature) => feature['properties']['formatted'] as String)
              .toList();

          setState(() {
            searchResults = results;
          });
        } else {
          print('No "features" key in the API response.');
        }
      } else {
        print('API Request Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> sendTransactionData() async {
    final apiUrl = 'https://lpg-api-06n8.onrender.com/api/v1/transactions';

    final CartProvider cartProvider =
        Provider.of<CartProvider>(context, listen: false);
    final List<Map<String, dynamic>> itemsList =
        convertCartItems(cartProvider.cartItems);
    double totalPrice = cartProvider.calculateTotalPrice();

    final UserProvider userProvider =
        Provider.of<UserProvider>(context, listen: false);
    final String userId = userProvider.userId ?? '';

    if (userId == null || userId.isEmpty) {
      print('Error: User ID is null or empty.');
      // You might want to display an error message to the user.
      return;
    }
    final Map<String, dynamic> requestData = {
      "deliveryLocation": locationController.text,
      "name": nameController.text,
      "contactNumber": contactNumberController.text,
      "houseLotBlk": houseNumberController.text,
      "paymentMethod": selectedPaymentMethod.toString(),
      "assembly": selectedAssemblyOption.toString(),
      "deliveryTime": selectedDateTime.toString(),
      "barangay": selectedBarangay,
      "total": totalPrice.toString(),
      "items": itemsList,
      "retailer": userId,
      "rider": "",
      "hasFeedback": "false",
      "feedback": "",
      "rating": "0",
      "pickupImages": "",
      "completionImages": "",
      "cancellationImages": "",
      "cancelReason": "",
      "pickedUp": "false",
      "cancelled": "false",
      "completed": "false",
      "type": "{Online}",
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: json.encode(requestData),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        print('Transaction successful');
        print('Response: ${response.body}');
        // If the transaction is successful, you can proceed with navigation.
        Navigator.pushNamed(context, myOrdersPage);
      } else {
        print('Transaction failed with status code: ${response.statusCode}');
        print('Response: ${response.body}');
        // You might want to display an error message to the user.
      }
    } catch (e) {
      print('Error: $e');
      // Handle other types of errors, if any.
      // You might want to display an error message to the user.
    }
  }

  Future<void> showConfirmationDialog() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirmation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Delivery Location: ${locationController.text}'),
              Text('Name: ${nameController.text}'),
              Text('Contact Number: ${contactNumberController.text}'),
              Text('House#/Lot/Blk: ${houseNumberController.text}'),
              Text('Barangay $selectedBarangay'),
              Text('Scheduled Date and Time: ${selectedDateTime.toString()}'),
              Text('Payment Method: ${selectedPaymentMethod.toString()}'),
              Text(
                  'Needs to be assembled: ${selectedAssemblyOption.toString()}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await sendTransactionData(); // Wait for the transaction to complete.
                // The navigation is now done inside sendTransactionData.
              },
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  Future<void> confirmDialog() async {
    selectedDateTime = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirmation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Delivery Location: ${locationController.text}'),
              Text('Name: ${nameController.text}'),
              Text('Contact Number: ${contactNumberController.text}'),
              Text('House#/Lot/Blk: ${houseNumberController.text}'),
              Text('Barangay $selectedBarangay'),
              Text('Scheduled Date and Time: ${selectedDateTime.toString()}'),
              Text('Payment Method: ${selectedPaymentMethod.toString()}'),
              Text(
                  'Needs to be assembled: ${selectedAssemblyOption.toString()}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await sendTransactionData(); // Wait for the transaction to complete.
                // The navigation is now done inside sendTransactionData.
              },
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  String? selectedBarangay;
  final List<String> barangays = [
    'Bagumbayan'
        'Bambang'
        'Calzada Tipas'
        'Cembo'
        'Central Bicutan'
        'Central Signal Village'
        'Cembo'
        'Comembo'
        'East Rembo'
        'Fort Bonifacio'
        'Hagonoy'
        'Ibayo Tipas'
        'Katuparan'
        'Ligid Tipas'
        'Lower Bicutan'
        'Maharlika Village'
        'Napindan'
        'New Lower Bicutan'
        'North Daang Hari'
        'North Signal Village'
        'Palingon Tipas'
        'Pembo'
        'Pinagsama'
        'Pitogo'
        'Post Proper Northside'
        'Post Proper Southside'
        'Rizal'
        'San Miguel'
        'Santa Ana'
        'South Cembo'
        'South Daang Hari'
        'South Signal Village'
        'Tanyag'
        'Tuktukan'
        'Ususan'
        'Upper Bicutan'
        'Wawa'
        'West Rembo'
        'Western Bicutan'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Set Delivery',
          style: TextStyle(color: Color(0xFF232937), fontSize: 24),
        ),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              children: [
                const Text(
                  "Set Delivery Location",
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: Column(
                    children: [
                      LocationSearchWidget(
                        locationController: locationController,
                        onLocationChanged: (query) {
                          fetchLocationData(query);
                        },
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        itemCount: searchResults.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(searchResults[index]),
                            onTap: () {
                              setState(() {
                                selectedLocation = searchResults[index];
                                locationController.text = searchResults[index];
                                searchResults = [];
                              });
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                LocationButtonWidget(
                  onLocationChanged: (String address) {
                    locationController.text = address;
                  },
                ),
                CustomTextField1(
                  labelText: 'Name',
                  hintText: 'Enter your Name',
                  controller: nameController,
                ),
                CustomTextField1(
                  labelText: 'Contact Number',
                  hintText: 'Enter your contact number',
                  controller: contactNumberController,
                ),
                CustomTextField1(
                  labelText: 'House#/Lot/Blk',
                  hintText: 'Enter your house number',
                  controller: houseNumberController,
                ),
                const SizedBox(height: 20),
                const Text("Choose Barangay"),
                DropdownButtonFormField<String>(
                  value: selectedBarangay,
                  items: barangays.map((barangay) {
                    return DropdownMenuItem<String>(
                      value: barangay,
                      child: Text(barangay),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    setState(() {
                      selectedBarangay = value;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Barangay',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                const Text("Choose Payment Method"),
                ListTile(
                  title: const Text('Cash On Delivery'),
                  leading: Radio<PaymentMethod>(
                    value: PaymentMethod.cashOnDelivery,
                    groupValue: selectedPaymentMethod,
                    onChanged: (PaymentMethod? value) {
                      setState(() {
                        selectedPaymentMethod = value;
                      });
                    },
                  ),
                ),
                ListTile(
                  title: const Text('Gcash Payment'),
                  leading: Radio<PaymentMethod>(
                    value: PaymentMethod.gcashPayment,
                    groupValue: selectedPaymentMethod,
                    onChanged: (PaymentMethod? value) {
                      setState(() {
                        selectedPaymentMethod = value;
                      });
                    },
                  ),
                ),
                Text("Needs to be assembled?"),
                ListTile(
                  title: const Text('Yes'),
                  leading: Radio<AssemblyOption>(
                    value: AssemblyOption.yes,
                    groupValue: selectedAssemblyOption,
                    onChanged: (AssemblyOption? value) {
                      setState(() {
                        selectedAssemblyOption = value;
                      });
                    },
                  ),
                ),
                ListTile(
                  title: const Text('No'),
                  leading: Radio<AssemblyOption>(
                    value: AssemblyOption.no,
                    groupValue: selectedAssemblyOption,
                    onChanged: (AssemblyOption? value) {
                      setState(() {
                        selectedAssemblyOption = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomizedButton(
                onPressed: () async {
                  final selectedDate = await showDateTimePicker(context);
                  if (selectedDate != null) {
                    setState(() {
                      selectedDateTime = selectedDate;
                      showConfirmationDialog();
                    });
                  }
                },
                text: 'Scheduled',
                height: 50,
                width: 180,
                fontz: 20,
              ),
              CustomizedButton(
                onPressed: () {
                  confirmDialog();
                },
                text: 'Deliver Now',
                height: 50,
                width: 180,
                fontz: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
