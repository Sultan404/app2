import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:second/copm/button.dart';
import 'package:second/copm/doubleform.dart';
import 'package:second/copm/textformAdd.dart';

class addFood extends StatefulWidget {
  const addFood({super.key});

  @override
  State<addFood> createState() => _addFoodState();
}

class _addFoodState extends State<addFood> {
  GlobalKey<FormState> formState = GlobalKey<FormState>();
  TextEditingController name = TextEditingController();
  TextEditingController image = TextEditingController();
  TextEditingController price = TextEditingController();

  CollectionReference category =
      FirebaseFirestore.instance.collection('category');

  Future<void> addUser() {
    // Call the user's CollectionReference to add a new user
    return category
        .add({
          'name': name.text,
          'prise': double.parse(price.text),
          'image': image.text,

        })
        .then((value) {
        print("Category added.");
        Navigator.of(context).pushNamed("homePage");
      })
        .catchError((error) => print("Failed to add category  : $error"));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("add")),
        body: Form(
          key: formState,
          child: Column(
            children: [
              Container(
                  padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                  child: CustomTextFormaAdd(
                    hinttext: "Enter name",
                    mycontroller: name,
                    validator: (val) {
                      if (val == "") {
                        return "cann't be empty";
                      }
                    },
                  )),
              Container(
                child: doubleform(
                    
                    doubleController: price,
                    
                    ),
              ),
              Container(
                  padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                  child: CustomTextFormaAdd(
                    hinttext: "Enter image source",
                    mycontroller: image,
                    validator: (val) {
                      if (val == "") {
                        return "cann't be empty";
                      }
                    },
                  )),
              
              button(
                txt: "add",
                onPressed: () {
                  addUser();
                },
              )
            ],
          ),
        ));
  }
}
