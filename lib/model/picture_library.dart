import 'dart:math' as math;

import 'picture.dart';

/// Uygulamadaki tüm resimler. Hepsi bu proje için çizilmiş özgün, basit şekillerdir.
/// 0-4 yaş için az sayıda, büyük ve kolay boyanan alan tercih edildi.
class PictureLibrary {
  PictureLibrary._();

  static final sun = picture('gunes', 'Güneş', (b) {
    b.background();
    b.cloud(210, 170, 280);
    b.cloud(790, 860, 260);
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      final half = 0.22;
      b.poly([
        (500 + 245 * math.cos(a - half)),
        (500 + 245 * math.sin(a - half)),
        (500 + 410 * math.cos(a)),
        (500 + 410 * math.sin(a)),
        (500 + 245 * math.cos(a + half)),
        (500 + 245 * math.sin(a + half)),
      ]);
    }
    b.circle(500, 500, 225);
    b.circle(425, 455, 30);
    b.circle(575, 455, 30);
    b.circle(375, 545, 32);
    b.circle(625, 545, 32);
    b.arc(400, 440, 600, 620, 20, 140);
  });

  static final cat = picture('kedi', 'Kedi', (b) {
    b.background();
    b.poly([250, 470, 290, 150, 470, 320]);
    b.poly([295, 420, 312, 235, 415, 330]);
    b.poly([750, 470, 710, 150, 530, 320]);
    b.poly([705, 420, 688, 235, 585, 330]);
    b.circle(500, 560, 290);
    b.oval(350, 440, 450, 560);
    b.oval(550, 440, 650, 560);
    b.oval(382, 470, 428, 548);
    b.oval(582, 470, 628, 548);
    b.poly([465, 610, 535, 610, 500, 655]);
    b.arc(440, 620, 500, 690, 0, 180);
    b.arc(500, 620, 560, 690, 0, 180);
    b.line([330, 620, 170, 590]);
    b.line([330, 655, 170, 665]);
    b.line([670, 620, 830, 590]);
    b.line([670, 655, 830, 665]);
  });

  static final fish = picture('balik', 'Balık', (b) {
    b.background();
    b.rect(0, 860, 1000, 1000);
    b.leaf(110, 870, 30, 700, 140, 560, 210, 720);
    b.leaf(880, 870, 800, 740, 900, 640, 960, 760);
    b.poly([690, 500, 900, 330, 900, 670]);
    b.poly([380, 345, 480, 200, 600, 340]);
    b.poly([450, 650, 520, 760, 585, 655]);
    b.oval(200, 330, 740, 670);
    b.circle(330, 470, 42);
    b.circle(340, 475, 18);
    b.arc(380, 400, 460, 600, -60, 120);
    b.circle(800, 230, 32);
    b.circle(740, 130, 22);
    b.circle(850, 85, 16);
  });

  static final apple = picture('elma', 'Elma', (b) {
    b.background();
    b.roundRect(482, 200, 522, 380, 20);
    b.leaf(520, 300, 600, 170, 740, 230, 650, 350);
    b.union([circlePath(400, 580, 240), circlePath(600, 580, 240)]);
    b.arc(300, 420, 440, 560, 190, 70);
  });

  static final balloons = picture('balonlar', 'Balonlar', (b) {
    b.background();
    b.rect(0, 900, 1000, 1000);
    b.line([300, 545, 470, 880]);
    b.line([500, 475, 470, 880]);
    b.line([700, 545, 470, 880]);
    b.oval(170, 180, 430, 520);
    b.poly([285, 545, 315, 545, 300, 515]);
    b.oval(570, 180, 830, 520);
    b.poly([685, 545, 715, 545, 700, 515]);
    b.oval(370, 90, 630, 450);
    b.poly([485, 475, 515, 475, 500, 445]);
  });

  static final flower = picture('cicek', 'Çiçek', (b) {
    b.background();
    b.cloud(200, 150, 240);
    b.rect(0, 840, 1000, 1000);
    b.roundRect(482, 480, 518, 880, 18);
    b.leaf(500, 720, 380, 600, 280, 680, 360, 780);
    b.leaf(500, 660, 620, 540, 720, 620, 640, 720);
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3 - math.pi / 2;
      b.circle((500 + 150 * math.cos(a)), (370 + 150 * math.sin(a)), 88);
    }
    b.circle(500, 370, 95);
    b.arc(450, 330, 550, 420, 20, 140);
  });

  static final butterfly = picture('kelebek', 'Kelebek', (b) {
    b.background();
    b.oval(130, 190, 500, 520);
    b.oval(500, 190, 870, 520);
    b.oval(200, 470, 500, 760);
    b.oval(500, 470, 800, 760);
    b.circle(310, 350, 60);
    b.circle(690, 350, 60);
    b.circle(350, 620, 45);
    b.circle(650, 620, 45);
    b.roundRect(465, 280, 535, 760, 35);
    b.circle(500, 250, 55);
    b.line([480, 205, 425, 110]);
    b.line([520, 205, 575, 110]);
    b.circle(415, 95, 22);
    b.circle(585, 95, 22);
  });

  static final car = picture('araba', 'Araba', (b) {
    b.background();
    b.cloud(250, 170, 260);
    b.rect(0, 790, 1000, 1000);
    b.poly([270, 490, 360, 320, 650, 320, 760, 490]);
    b.roundRect(110, 480, 890, 700, 50);
    b.poly([320, 480, 385, 350, 495, 350, 495, 480]);
    b.poly([525, 480, 525, 350, 630, 350, 700, 480]);
    b.circle(855, 560, 24);
    b.roundRect(112, 530, 145, 590, 8);
    b.circle(300, 710, 95);
    b.circle(700, 710, 95);
    b.circle(300, 710, 38);
    b.circle(700, 710, 38);
    b.line([510, 500, 510, 640]);
    b.line([545, 535, 590, 535]);
    b.line([80, 910, 200, 910]);
    b.line([420, 910, 540, 910]);
    b.line([760, 910, 880, 910]);
  });

  static final house = picture('ev', 'Ev', (b) {
    b.background();
    b.circle(140, 140, 80);
    b.cloud(700, 150, 240);
    b.rect(0, 800, 1000, 1000);
    b.poly([470, 820, 530, 820, 580, 1000, 420, 1000]);
    b.rect(620, 230, 700, 400);
    b.rect(250, 460, 750, 820);
    b.poly([190, 480, 500, 210, 810, 480]);
    b.roundRect(440, 620, 560, 820, 24);
    b.circle(535, 725, 12);
    b.rect(300, 530, 400, 630);
    b.rect(600, 530, 700, 630);
    b.line([350, 530, 350, 630]);
    b.line([300, 580, 400, 580]);
    b.line([650, 530, 650, 630]);
    b.line([600, 580, 700, 580]);
  });

  static final List<ColoringPicture> all = [
    sun,
    cat,
    fish,
    apple,
    balloons,
    flower,
    butterfly,
    car,
    house,
  ];

  static ColoringPicture? byId(String id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    return null;
  }
}
