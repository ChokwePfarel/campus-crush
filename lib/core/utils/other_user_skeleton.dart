import 'package:flutter/material.dart';
import 'package:dating_app/core/utils/screen_size.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class OtherUserSkeleton extends StatelessWidget {
  const OtherUserSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    return Shimmer(
      duration: const Duration(seconds: 2),
      interval: const Duration(milliseconds: 500),
      color: Colors.grey.shade300,
      colorOpacity: 0.3,
      enabled: true,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile header image skeleton
            Container(
              height: SizeConfig.heightPercent(50),
              width: double.infinity,
              color: Colors.grey[300],
            ),

            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.widthPercent(5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and age skeleton
                  Container(
                    height: SizeConfig.widthPercent(7),
                    width: SizeConfig.widthPercent(40),
                    color: Colors.grey[300],
                  ),
                  SizedBox(height: SizeConfig.heightPercent(1)),

                  // Major skeleton
                  Container(
                    height: SizeConfig.widthPercent(4.5),
                    width: SizeConfig.widthPercent(30),
                    color: Colors.grey[300],
                  ),
                  SizedBox(height: SizeConfig.heightPercent(0.5)),

                  // University skeleton
                  Container(
                    height: SizeConfig.widthPercent(3.5),
                    width: SizeConfig.widthPercent(45),
                    color: Colors.grey[300],
                  ),
                  SizedBox(height: SizeConfig.heightPercent(2)),

                  // Status chip skeleton
                  Container(
                    height: SizeConfig.heightPercent(3),
                    width: SizeConfig.widthPercent(25),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(SizeConfig.widthPercent(2)),
                    ),
                  ),
                  SizedBox(height: SizeConfig.heightPercent(3)),

                  // About Me title skeleton
                  Container(
                    height: 20,
                    width: SizeConfig.widthPercent(25),
                    color: Colors.grey[300],
                  ),
                  SizedBox(height: SizeConfig.heightPercent(1)),

                  // Bio text lines skeleton
                  Container(
                    height: SizeConfig.widthPercent(4),
                    width: double.infinity,
                    color: Colors.grey[300],
                  ),
                  SizedBox(height: SizeConfig.heightPercent(0.5)),
                  Container(
                    height: SizeConfig.widthPercent(4),
                    width: SizeConfig.widthPercent(80),
                    color: Colors.grey[300],
                  ),
                  SizedBox(height: SizeConfig.heightPercent(0.5)),
                  Container(
                    height: SizeConfig.widthPercent(4),
                    width: SizeConfig.widthPercent(60),
                    color: Colors.grey[300],
                  ),
                  SizedBox(height: SizeConfig.heightPercent(3)),

                  // Interests title skeleton
                  Container(
                    height: 20,
                    width: SizeConfig.widthPercent(20),
                    color: Colors.grey[300],
                  ),
                  SizedBox(height: SizeConfig.heightPercent(1.5)),

                  // Interests chips skeleton
                  Wrap(
                    spacing: SizeConfig.widthPercent(2),
                    runSpacing: SizeConfig.widthPercent(2),
                    children: List.generate(6, (index) => Container(
                      height: 32,
                      width: SizeConfig.widthPercent(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(16),
                      ),
                    )),
                  ),
                  SizedBox(height: SizeConfig.heightPercent(3)),

                  // Gallery title skeleton
                  Container(
                    height: 20,
                    width: SizeConfig.widthPercent(18),
                    color: Colors.grey[300],
                  ),
                  SizedBox(height: SizeConfig.heightPercent(1.5)),

                  // Gallery grid skeleton
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: SizeConfig.widthPercent(3),
                      mainAxisSpacing: SizeConfig.widthPercent(3),
                      childAspectRatio: 0.8,
                    ),
                    itemCount: 4,
                    itemBuilder: (context, index) => Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(SizeConfig.widthPercent(4)),
                      ),
                    ),
                  ),
                  SizedBox(height: SizeConfig.heightPercent(15)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
