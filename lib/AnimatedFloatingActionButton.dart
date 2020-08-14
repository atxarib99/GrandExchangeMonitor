import 'package:flutter/material.dart';

class AnimatedFloatingActionButton extends StatefulWidget {

  _AnimatedFloatingActionButtonState fabs;

  AnimatedFloatingActionButton(Function() onPressed) {
    fabs = _AnimatedFloatingActionButtonState(onPressed);
  }

  @override
  _AnimatedFloatingActionButtonState createState() => fabs;

  void animate() {
    fabs.animate();
  }

}

class _AnimatedFloatingActionButtonState extends State<AnimatedFloatingActionButton>
    with SingleTickerProviderStateMixin {

  Function() onPressed;

  _AnimatedFloatingActionButtonState(Function() onPressed) {
    this.onPressed = onPressed;
  }

  bool isOpened = false;
  AnimationController _animationController;
  Animation<Color> _animateColor;
  Animation<double> _animateIcon;
  Curve _curve = Curves.easeOut;

  @override
  initState() {
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500))
          ..addListener(() {
            setState(() {});
          });
    _animateIcon =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _animateColor = ColorTween(
      begin: Colors.blue,
      end: Colors.red,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(
        0.00,
        1.00,
        curve: Curves.linearToEaseOut,
      ),
    ));
    super.initState();
  }

  @override
  dispose() {
    _animationController.dispose();
    super.dispose();
  }

  animate() {
    // if (!isOpened) {
    //   _animationController.forward();
    // } else {
    //   _animationController.reverse();
    // }
    // isOpened = !isOpened;
    _animationController.forward().whenComplete(() => _animationController.reverse());
  }

  Widget toggle() {
    return FloatingActionButton(
      backgroundColor: _animateColor.value,
      onPressed: this.onPressed,
      tooltip: 'Toggle',
      child: Icon(Icons.search),
    );
  }

  @override
  Widget build(BuildContext context) {
    return toggle();
  }
}