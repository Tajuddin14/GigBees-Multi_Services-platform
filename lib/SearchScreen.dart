import 'package:auth_test/OrganicFoods.dart';
import 'package:auth_test/ProfileSection/profilesection.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

class Searchscreen extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<Searchscreen> {
  int _currentIndex = 0;

  final List<Widget> _children = [
    HomeSection(),
    OrdersSection(),
    ProfileSection(),
  ];

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffdee2e6),
      appBar: AppBar(
        backgroundColor: Colors.green,
        automaticallyImplyLeading: false,
        centerTitle: false,
        toolbarHeight: 60,
        elevation: 7,
        scrolledUnderElevation: 100,
        shape: Border.all(color: Colors.white),
        title: Text("GigBees", style: GoogleFonts.poppins(fontSize: 35, fontWeight: FontWeight.w600)),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(onPressed: (){}, icon: Icon(Icons.search,size: 34,color: Colors.white,)),
          ),
        ],
      ),
      body: _children[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        elevation: 10,
        fixedColor: Color(0xff1b4332),
        backgroundColor: Color(0xff52b788),
        onTap: onTabTapped,
        currentIndex: _currentIndex,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_rounded),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class HomeSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 0.8),
          RectangularBox(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Align(
                alignment: Alignment.topLeft,
                child: Text("Book Now", style: GoogleFonts.poppins(fontSize: 21, fontWeight: FontWeight.w600))),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              BoxView(
                image: Image.asset('Assets/organic.png', width: 120),
                text: const Text("Organic Foods", style: TextStyle(fontSize: 16)),
                action: ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => OrganicFoods()));
                  },
                  child: Text("Book", style: GoogleFonts.poppins()),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, elevation: 10, foregroundColor: Colors.white),
                ),
              ),
              BoxView(
                image: Image.asset('Assets/saree.png', width: 120),
                text: const Text("Pattu Saree Wash", style: TextStyle(fontSize: 16)),
                action: ElevatedButton(
                  onPressed: () {},
                  child: Text("Book", style: GoogleFonts.poppins()),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, elevation: 10, foregroundColor: Colors.white),
                ),
              )
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              BoxView(
                image: Image.asset('Assets/housekeeper.png', width: 120),
                text: const Text("Maid", style: TextStyle(fontSize: 16)),
                action: ElevatedButton(
                  onPressed: () {},
                  child: Text("Book", style: GoogleFonts.poppins()),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, elevation: 10, foregroundColor: Colors.white),
                ),
              ),
              BoxView(
                image: Image.asset('Assets/doctor.png', width: 120),
                text: const Text("Doctor", style: TextStyle(fontSize: 16)),
                action: ElevatedButton(
                  onPressed: () {},
                  child: Text("Book", style: GoogleFonts.poppins()),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, elevation: 10, foregroundColor: Colors.white),
                ),
              )
            ],
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              BoxView(
                image: Image.asset('Assets/mehndi.png', width: 120),
                text: const Text("Mehndi Artist", style: TextStyle(fontSize: 16)),
                action: ElevatedButton(
                  onPressed: () {},
                  child: Text("Book", style: GoogleFonts.poppins()),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, elevation: 10, foregroundColor: Colors.white),
                ),
              ),
              BoxView(
                image: Image.asset('Assets/makeup.png', width: 120),
                text: const Text("Makeup Artist", style: TextStyle(fontSize: 16)),
                action: ElevatedButton(
                  onPressed: () {},
                  child: Text("Book", style: GoogleFonts.poppins()),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, elevation: 10, foregroundColor: Colors.white),
                ),
              )
            ],
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              BoxView(
                image: Image.asset('Assets/dryCleaning.png', width: 120),
                text: const Text("Dry Cleaning", style: TextStyle(fontSize: 16)),
                action: ElevatedButton(
                  onPressed: () {},
                  child: Text("Book", style: GoogleFonts.poppins()),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, elevation: 10, foregroundColor: Colors.white),
                ),
              ),
              BoxView(
                image: Image.asset('Assets/animal-care.png', width: 120),
                text: const Text("Pet Care", style: TextStyle(fontSize: 16)),
                action: ElevatedButton(
                  onPressed: () {},
                  child: Text("Book", style: GoogleFonts.poppins()),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, elevation: 10, foregroundColor: Colors.white),
                ),
              )
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              BoxView(
                image: Image.asset('Assets/plant-pot.png', width: 120),
                text: const Text("Plant Nursery", style: TextStyle(fontSize: 16)),
                action: ElevatedButton(
                  onPressed: () {},
                  child: Text("Book", style: GoogleFonts.poppins()),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, elevation: 10, foregroundColor: Colors.white),
                ),
              ),
              BoxView(
                image: Image.asset('Assets/mobile.png', width: 120),
                text: const Text("Mobile Repair", style: TextStyle(fontSize: 16)),
                action: ElevatedButton(
                  onPressed: () {},
                  child: Text("Book", style: GoogleFonts.poppins()),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, elevation: 10, foregroundColor: Colors.white),
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}

class OrdersSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Orders Section',
        style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class BoxView extends StatelessWidget {
  final Image image;
  final Text text;
  final ElevatedButton action;

  BoxView({
    required this.image,
    required this.text,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Card(
      elevation: 12,
      color: Color(0xffd8f3dc),
      child: Container(
        height: size.height * 0.28,
        width: size.width * 0.45,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            image,
            text,
            action,
          ],
        ),
      ),
    );
  }
}

class Add extends StatelessWidget {
  final List<Widget> ads = [
    Image.asset('Assets/Add3.jpg',fit: BoxFit.cover),
    Image.asset('Assets/Add4.jpg',fit: BoxFit.cover),
    Image.asset('Assets/Add5.jpg',fit: BoxFit.cover),
    Image.asset('Assets/Add6.jpg',fit: BoxFit.cover),
    Image.asset('Assets/Add7.png',fit: BoxFit.cover),
    Image.asset('Assets/Add8.png',fit: BoxFit.cover)
  ];

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return SizedBox(
      height: size.height * 0.23,
      width: size.width * 0.99,
      child: Card(
        shadowColor: Colors.lightGreenAccent,
        elevation: 10,
        child: AdvertisementScroller(ads: ads),
      ),
    );
  }
}

class AdvertisementScroller extends StatefulWidget {
  final List<Widget> ads;
  AdvertisementScroller({required this.ads});

  @override
  _AdvertisementScrollerState createState() => _AdvertisementScrollerState();
}

class _AdvertisementScrollerState extends State<AdvertisementScroller> {
  PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    Timer.periodic(Duration(seconds: 5), (Timer timer) {
      setState(() {
        _currentPage = (_currentPage + 1) % widget.ads.length;
      });

      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _pageController,
      children: widget.ads,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}


class RectangularBox extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    // TODO: implement build
    return SizedBox(
      width: size.width * 0.95,
      child: TextField(
        enabled: true,
        autofocus: true,
        focusNode: FocusNode(),
        onTap: (){
          // Code here for Search
        },
        decoration: InputDecoration(
          enabled: true,
            prefixIcon: Icon(Icons.search,size: 30),

            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: Colors.black)
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: Colors.black),
            ),
            errorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black),
              borderRadius: BorderRadius.circular(20),
            )
        ),
      ),
    );
  }
}

