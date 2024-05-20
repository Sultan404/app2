import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class doubleform extends StatelessWidget {
  final TextEditingController doubleController ;
  double? _enteredDouble;
  
  
  doubleform({super.key, required this.doubleController, });


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        child: Column(
          children: [
            TextFormField(
              controller: doubleController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
             
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a value';
                }
                try {
                  _enteredDouble = double.parse(value);
                } catch (e) {
                  return 'Invalid price format';
                }
                return null;
              },
              //  (value) {
              //   if (value == null || value.isEmpty) {
              //     return 'Please enter a value';
              //   }
              //   try {
              //     _enteredDouble = double.parse(value);
              //   } catch (e) {
              //     return 'Invalid double format';
              //   }
              //   return null;
              // },
            
            // SizedBox(height: 20),
            // ElevatedButton(
            //   onPressed: () {
            //     if (Form.of(context)!.validate()) {
            //       // Do something with the entered double value
            //       print('Entered Double: $_enteredDouble');
            //     }
            //   },
            //   child: Text('Submit'),
            // ),
           decoration: InputDecoration(
            labelText: 'Enter a Double..',
          
          hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
          contentPadding: EdgeInsets.symmetric(vertical: 2, horizontal: 20),
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50),
              borderSide:
                  BorderSide(color: const Color.fromARGB(255, 184, 184, 184))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50),
              borderSide: BorderSide(color: Colors.grey))),)
          ],
        ),
      ),
    );
  }
}