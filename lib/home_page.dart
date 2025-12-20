import 'package:flutter/material.dart';
import 'bottom_nav.dart';
import 'chats_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // A variable to hold the request that the user has joined.
  RideRequest? joinedRequest;

  // ===================== DATA =====================
  final List<Driver> drivers = [
    Driver('Danish', true, 'Muhammad Danish K.', 4, 'WWB 882', 'Black Myvi',
        'September 2025 - September 2026', 'assets/drivers/danish.jpg'),
    Driver('Bohan', true, 'Bohan Meduri', 3, 'VAJ 2312', 'Red Axia',
        'January 2025 - January 2026', 'assets/drivers/bohan.jpg'),
    Driver('Kurt', false, 'Kurt Ernest', 5, 'PNY 9031', 'Blue Persona',
        'November 2025 - November 2026', 'assets/drivers/kurt.jpg'),
    Driver('Samantha', false, 'Samantha G.', 3, 'AGT 2769', 'Black Honda Civic',
        'December 2025 - December 2026', 'assets/drivers/samantha.jpg'),
    Driver('Wayne', false, 'Wayne Rhine', 5, 'BMG 3371', 'White Myvi',
        'January 2025 - January 2026', 'assets/drivers/wayne.jpg'),
    Driver('Sarah', false, 'Sarah W.', 3, 'KHN 4021', 'Red Yaris',
        'November 2025 - November 2026', 'assets/drivers/sarah.jpg'),
    Driver('Rue', false, 'Rue Pyra', 4, 'PSR 8910', 'Blue Viva',
        'October 2025 - October 2026', 'assets/drivers/rue.jpg'),
  ];

  final List<RideRequest> requests = [
    RideRequest('MF', 'Farhan', 'Muhammad Farhan', 1, 'Terminal Sungai Nibong',
        'M01, Desasiswa Restu', 'Apr 1, 2025', '9:30 AM'),
    RideRequest('AN', 'Amira', 'Amira Nuria', 2, 'K05, Desasiswa Aman Damai',
        'Lotus Sungai Dua', 'Apr 1, 2025', '10:00 AM'),
    RideRequest('DY', 'Derrick', 'Derick Yuan', 4, 'Dewan Kuliah STUV',
        'SOLLAT, USM', 'Apr 1, 2025', '12:15 PM'),
    RideRequest('PH', 'Puteri', 'Puteri Hannah', 3, 'Desasiswa CGH',
        'Penang Airport', 'Apr 1, 2025', '12:45 PM'),
    RideRequest('MA', 'Akmal', 'Muhammad Akmal', 4, 'Desasiswa Indah Kembara',
        'KOPA Arena', 'Apr 2, 2025', '8:30 AM'),
    RideRequest('CH', 'Chung', 'Chung Hwatt', 4, 'M03, Desasiswa Saujana',
        'Dewan Kuliah SK1', 'Apr 2, 2025', '11:45 AM'),
    RideRequest('WB', 'Winanda', 'Winanda Bruce', 3, 'Dewan Kuliah G31',
        'Queensbay Mall', 'Apr 2, 2025', '5:00 PM'),
  ];

  // ===================== UI =====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 16,
        // CHANGED: Bigger and Bolder Text
        title: const Text(
          'Welcome, Adam.',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w800, // Extra Bold
            fontSize: 28, // Bigger size
          ),
        ),
        actions: [
          // CHANGES FOR LOGOUT AND SPACING: Re-added the logout button
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: _logoutReset,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Our Drivers',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            height: 120,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: drivers.length,
              separatorBuilder: (_, __) => const SizedBox(width: 18),
              itemBuilder: (_, i) => _driverItem(drivers[i]),
            ),
          ),
          // MODIFIED: Increased SizedBox height for better spacing
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            child: Text(
              'Ongoing Requests',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          // MODIFIED: Reduced SizedBox height further
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: requests.length,
              itemBuilder: (_, i) => _requestCard(requests[i]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }

  // ===================== DRIVER ITEM =====================
  Widget _driverItem(Driver d) {
    return GestureDetector(
      onTap: () => _showDriverDialog(d),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(radius: 42, backgroundImage: AssetImage(d.image)),
              Positioned(
                bottom: 4,
                right: 4,
                child: CircleAvatar(
                  radius: 7,
                  backgroundColor: d.isOnline ? Colors.green : Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            d.shortName,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // ===================== DRIVER POPUP =====================
  void _showDriverDialog(Driver d) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        // MODIFIED: Dialog color to white
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(radius: 42, backgroundImage: AssetImage(d.image)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      5,
                      (i) => Icon(
                        Icons.star,
                        size: 20,
                        color:
                            i < d.rating ? Colors.amber : Colors.grey.shade300,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    d.fullName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${d.plate} · ${d.car}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 20),
                  // CHANGED: License Validity Text Style
                  const Text(
                    "License Validity",
                    style: TextStyle(
                        fontSize: 14, // Same size as body text
                        color: Colors.black87,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    d.license,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ),
            _closeBtn(),
          ],
        ),
      ),
    );
  }

  // ===================== REQUEST CARD =====================
  Widget _requestCard(RideRequest r) {
    final bool isJoined = joinedRequest == r;
    final bool isFull = r.joined >= 4;

    // Logic for button state
    String btnText;
    Color btnColor;
    VoidCallback? btnAction;

    if (isJoined) {
      btnText = "Joined";
      btnColor = Colors.grey.shade600; // Use a slightly darker grey for Joined
      btnAction = null; // Disable button visual click
    } else if (isFull) {
      btnText = "Full";
      btnColor = Colors.grey.shade600; // Use a slightly darker grey for Full
      btnAction = null;
    } else {
      btnText = "Join";
      // MODIFIED: Darker color to match the screenshot
      btnColor = const Color(0xFF333333);
      // CHANGED: If user has a request but it's not this one, show error popup
      if (joinedRequest != null) {
        btnAction = _showAlreadyJoinedError;
      } else {
        btnAction = () => _showJoinConfirm(r);
      }
    }

    // MODIFIED: Used Color(0xFFEFEFEF) for a light grey card background
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFEF),
        borderRadius: BorderRadius.circular(16), // MODIFIED: Softer corner
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 30, // MODIFIED: Larger radius
                backgroundColor: Colors.white,
                child: Text(r.initials,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, // MODIFIED: Bolder text
                        fontSize: 23, // MODIFIED: Larger text
                        color: Colors.black)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.displayName,
                    style: const TextStyle(
                        fontSize: 22, // MODIFIED: Larger text
                        fontWeight: FontWeight.bold), // MODIFIED: Bolder text
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text('${r.joined}/4',
                          style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 4),
                      const Icon(Icons.person_outline, size: 15),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  // MODIFIED: Passed the specific font size for the pills
                  _pill(r.date, fontSize: 13),
                  const SizedBox(width: 6),
                  // MODIFIED: Passed the specific font size for the pills
                  _pill(r.time, fontSize: 13),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // MODIFIED: Wrapped the details with padding to reduce overall width
          // giving a more 'centered' look by pulling away from the left/right edge.
          Padding(
            padding: const EdgeInsets.only(
                left: 8, right: 8), // MODIFIED: Less padding here
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoLine('Pick-up:', r.pickup),
                      const SizedBox(height: 8), // MODIFIED: Reduced space between lines
                      _infoLine('Destination:', r.destination),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 90,
                  height: 45, // MODIFIED: Set fixed height
                  child: _btn(
                    btnText,
                    btnColor,
                    btnAction,
                    textColor: Colors.white,
                    fontSize: 18, // MODIFIED: Larger font size for the main button
                    fontWeight: FontWeight.bold, // MODIFIED: Bold font weight
                    borderRadius: 14, // MODIFIED: Set specific border radius
                  ),
                ),
              ],
            ),
          ),
          if (isJoined) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8), // MODIFIED: Add horizontal padding to align with details
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40, // MODIFIED: Set height for the small buttons
                      child: _btn('Cancel', Colors.red, () {
                        setState(() {
                          r.joined--;
                          joinedRequest = null;
                        });
                      },
                          // MODIFIED: Reduced font size for smaller buttons
                          textColor: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500, // MODIFIED: Medium font weight
                          borderRadius: 12), // MODIFIED: Softer corner
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 40, // MODIFIED: Set height for the small buttons
                      child: _btn('Group Chat', const Color(0xFF007AFF), () {
                        // MODIFIED: Specific bright blue color
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ChatsPage()),
                        );
                      },
                          // MODIFIED: Reduced font size for smaller buttons
                          textColor: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500, // MODIFIED: Medium font weight
                          borderRadius: 12), // MODIFIED: Softer corner
                    ),
                  ),
                ],
              ),
            )
          ]
        ],
      ),
    );
  }

  // ===================== ERROR POPUP (ALREADY JOINED) =====================
  void _showAlreadyJoinedError() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        // MODIFIED: Dialog color to white
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.warning_amber_rounded,
                      size: 48, color: Colors.orange),
                  SizedBox(height: 16),
                  Text(
                    "You have an ongoing trip",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "You can only join one trip at a time. Please cancel your current trip before joining another.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
            _closeBtn(),
          ],
        ),
      ),
    );
  }

  // ===================== JOIN CONFIRM =====================
  void _showJoinConfirm(RideRequest r) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        // MODIFIED: Dialog color to white
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          // Removed Stack, so no close button
          padding: const EdgeInsets.all(24),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              // MODIFIED: Align everything in this column to the center
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text('Join this ride?',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _popupRow('Trip by:', r.fullName, isCentered: true),
                _popupRow('Date:', r.date, isCentered: true),
                _popupRow('Time:', r.time, isCentered: true),
                _popupRow('Pick-up:', r.pickup, isCentered: true),
                _popupRow('Destination:', r.destination, isCentered: true),
                const SizedBox(height: 24),
                Row(children: [
                  Expanded(
                    child:
                        _btn('Cancel', Colors.red, () => Navigator.pop(context)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _btn('Confirm', Colors.green, () {
                      Navigator.pop(context);
                      setState(() {
                        r.joined++;
                        joinedRequest = r;
                      });
                      _showSuccess();
                    }),
                  ),
                ])
              ]),
        ),
      ),
    );
  }

  // ===================== SUCCESS POPUP =====================
  void _showSuccess() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        // MODIFIED: Dialog color to white
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(mainAxisSize: MainAxisSize.min, children: const [
                Text('✅', style: TextStyle(fontSize: 56)),
                SizedBox(height: 16),
                Text(
                  "You’ve successfully joined the trip!",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  "The creator has been notified.\nYou can view this ride in Orders.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
              ]),
            ),
            _closeBtn(),
          ],
        ),
      ),
    );
  }

  // ===================== HELPERS =====================
  Widget _btn(String text, Color color, VoidCallback? onTap,
          {Color textColor = Colors.white,
          double fontSize = 14,
          FontWeight fontWeight =
              FontWeight.normal, // MODIFIED: Added fontWeight parameter
          double borderRadius = 10}) => // MODIFIED: Added borderRadius parameter
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            disabledBackgroundColor: color,
            disabledForegroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(borderRadius)), // MODIFIED: Use parameter
            elevation: 0,
            padding: EdgeInsets.zero,
          ),
          child: Text(text,
              style: TextStyle(
                  color: textColor,
                  fontSize: fontSize,
                  fontWeight: fontWeight), // MODIFIED: Use parameter
              textAlign: TextAlign.center),
        ),
      );

  // MODIFIED: Adjusted for size, padding, color and border radius to match screenshot
  Widget _pill(String text, {double fontSize = 12}) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 6), // MODIFIED: Tighter vertical padding
        decoration: BoxDecoration(
            color: const Color(0xFFD6D6D6), // MODIFIED: Specific opaque grey color
            borderRadius:
                BorderRadius.circular(12)), // MODIFIED: Smaller border radius
        child: Text(text,
            // MODIFIED: Use the passed fontSize
            style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600, // MODIFIED: Slightly bolder text
                color: Colors.black87)), // MODIFIED: Darker text color
      );

  // MODIFIED: Added isCentered logic for the confirmation popup
  Widget _popupRow(String label, String value, {bool isCentered = false}) {
    if (isCentered) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            Text(label, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 2),
            Text(value,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
          ],
        ),
      );
    }

    // Original implementation for non-centered rows (not used in this scenario)
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        SizedBox(width: 100, child: Text(label)),
        Expanded(child: Text(value)),
      ]),
    );
  }

  // CHANGES FOR LOGOUT AND SPACING: Adjusted the width of the label column.
  Widget _infoLine(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                // CHANGES FOR LOGOUT AND SPACING: Increased width for better separation
                width: 95, 
                child: Text('$label ',
                    style: const TextStyle(
                        fontSize: 15, // MODIFIED: Larger font size
                        color: Colors.black54))),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      // MODIFIED: Used w600 for a less heavy look
                      fontWeight: FontWeight.w600,
                      fontSize: 15), // MODIFIED: Larger font size
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      );

  Widget _closeBtn() => Positioned(
        top: 4,
        right: 4,
        child: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      );

  void _logoutReset() {
    // Note: You would typically navigate back to the login screen here.
    // For now, it just resets the joined request.
    setState(() {
      if (joinedRequest != null) {
        joinedRequest!.joined--;
        joinedRequest = null;
      }
    });
    // Add navigation logic here, e.g., Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
  }
}

// ===================== MODELS =====================
class Driver {
  final String shortName;
  final bool isOnline;
  final String fullName;
  final int rating;
  final String plate;
  final String car;
  final String license;
  final String image;

  Driver(this.shortName, this.isOnline, this.fullName, this.rating, this.plate,
      this.car, this.license, this.image);
}

class RideRequest {
  final String initials;
  final String displayName;
  final String fullName;
  int joined;
  final String pickup;
  final String destination;
  final String date;
  final String time;

  RideRequest(this.initials, this.displayName, this.fullName, this.joined,
      this.pickup, this.destination, this.date, this.time);
}