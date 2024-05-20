import 'package:flutter/material.dart';

class button extends StatelessWidget {
  final String txt;
final void Function()? onPressed;
const button({super.key,required this.txt, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
            height: 50,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(70)),
            color:  Colors.blue,
            onPressed: onPressed,
            child:  Text(
              txt,
              style: TextStyle(color: Colors.white),
            ),
          );
  }
}
