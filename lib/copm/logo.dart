import 'package:flutter/material.dart';

class logo extends StatelessWidget{

const logo({super.key});

@override
Widget build(BuildContext context){
  return Center(
                child: Container(
                    alignment: Alignment.center,
                    width: 250,
                    height: 250,
                      
                    decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(75)),
                    child: Image.asset(
                      "image/holek.png",
                      width: 249,
                      height: 249,
                       //fit: BoxFit.fill,
                    )),
              );
}


}