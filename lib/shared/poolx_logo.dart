import 'package:flutter/material.dart';

class PoolxLogo extends StatelessWidget {
  final double height;

  const PoolxLogo({super.key, this.height = 22});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/poolx_topbar.png',
      height: height,
      fit: BoxFit.contain,
    );
  }
}

class PoolxAuthLogo extends StatelessWidget {
  const PoolxAuthLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/logo.png',
          width: 50,
          color: Colors.white,
          colorBlendMode: BlendMode.srcIn,
          filterQuality: FilterQuality.high,
        ),
        const SizedBox(height: 4),
        const Text(
          'POOLX',
          style: TextStyle(
            color: Color(0xFF06C167),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 5,
          ),
        ),
      ],
    );
  }
}
