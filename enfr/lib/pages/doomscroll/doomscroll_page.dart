import 'package:carousel_slider/carousel_slider.dart';
import 'package:enfr/pages/doomscroll/widgets/verb_test.dart';
import 'package:enfr/widgets/enfr_scaffold.dart';
import 'package:flutter/material.dart';

class DoomscrollPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _DoomscrollPageState();
}

class _DoomscrollPageState extends State<DoomscrollPage> {
  @override
  Widget build(BuildContext context) => EnfrScaffold(
        title: "Doomscroll",
        body: body(context),
      );

  Widget body(BuildContext context) => CarouselSlider.builder(
        options: CarouselOptions(
          height: 600.0,
          viewportFraction: 1.0,
          // aspectRatio: 6 / 9,
          scrollDirection: Axis.vertical,
        ),
        itemCount: 3,
        itemBuilder: (BuildContext context, int itemIndex, int pageViewIndex) {
          return VerbTest();
          return Container(
              width: MediaQuery.of(context).size.width,
              //height: MediaQuery.of(context).size.height,
              margin: EdgeInsets.symmetric(horizontal: 5.0),
              decoration: BoxDecoration(color: Colors.amber),
              child: Text(
                'text',
                style: TextStyle(fontSize: 16.0),
              ));
        },
        // items: [1, 2, 3, 4, 5].map((i) {
        //   return Builder(
        //     builder: (BuildContext context) {
        //       return Container(
        //           width: MediaQuery.of(context).size.width,
        //           //height: MediaQuery.of(context).size.height,
        //           margin: EdgeInsets.symmetric(horizontal: 5.0),
        //           decoration: BoxDecoration(color: Colors.amber),
        //           child: Text(
        //             'text $i',
        //             style: TextStyle(fontSize: 16.0),
        //           ));
        //     },
        //   );
        // }).toList(),
      );
}
