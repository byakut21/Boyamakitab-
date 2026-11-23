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

  static final rabbit = picture('tavsan', 'Tavşan', (b) {
    b.background();
    b.rect(0, 850, 1000, 1000);
    b.oval(330, 80, 450, 420);
    b.oval(360, 130, 420, 380);
    b.oval(550, 80, 670, 420);
    b.oval(580, 130, 640, 380);
    b.oval(300, 560, 700, 920);
    b.oval(400, 660, 600, 880);
    b.circle(500, 500, 190);
    b.circle(430, 470, 24);
    b.circle(570, 470, 24);
    b.circle(395, 555, 30);
    b.circle(605, 555, 30);
    b.oval(475, 528, 525, 566);
    b.arc(450, 540, 500, 600, 0, 180);
    b.arc(500, 540, 550, 600, 0, 180);
    b.oval(310, 860, 460, 940);
    b.oval(540, 860, 690, 940);
  });

  static final bird = picture('kus', 'Kuş', (b) {
    b.background();
    b.cloud(220, 180, 260);
    b.cloud(800, 120, 200);
    b.poly([330, 560, 160, 470, 190, 640]);
    b.roundRect(60, 700, 940, 750, 25);
    b.leaf(160, 700, 120, 600, 60, 590, 120, 680);
    b.leaf(840, 700, 880, 600, 940, 590, 880, 680);
    b.circle(500, 510, 200);
    b.oval(400, 510, 620, 700);
    b.leaf(400, 500, 500, 400, 630, 510, 520, 640);
    b.poly([690, 470, 790, 500, 690, 530]);
    b.circle(600, 440, 30);
    b.circle(607, 445, 13);
  });

  static final turtle = picture('kaplumbaga', 'Kaplumbağa', (b) {
    b.background();
    b.circle(150, 150, 80);
    b.rect(0, 820, 1000, 1000);
    b.oval(280, 640, 390, 800);
    b.oval(610, 640, 720, 800);
    b.poly([220, 640, 130, 700, 230, 700]);
    b.circle(800, 560, 95);
    b.oval(220, 330, 780, 720);
    b.roundRect(190, 620, 810, 700, 35);
    b.circle(500, 470, 75);
    b.circle(345, 545, 50);
    b.circle(655, 545, 50);
    b.circle(390, 410, 40);
    b.circle(610, 410, 40);
    b.circle(830, 535, 16);
    b.arc(770, 560, 850, 615, 20, 120);
  });

  static final boat = picture('tekne', 'Tekne', (b) {
    b.background();
    b.circle(830, 160, 80);
    b.cloud(220, 150, 240);
    b.rect(0, 720, 1000, 1000);
    b.rect(490, 130, 510, 640);
    b.poly([510, 130, 600, 155, 510, 180]);
    b.poly([525, 200, 525, 590, 790, 590]);
    b.poly([475, 250, 475, 590, 280, 590]);
    b.poly([150, 620, 850, 620, 740, 810, 260, 810]);
    b.circle(360, 700, 30);
    b.circle(500, 700, 30);
    b.circle(640, 700, 30);
    b.arc(60, 860, 180, 920, 180, 180);
    b.arc(380, 900, 500, 960, 180, 180);
    b.arc(760, 860, 880, 920, 180, 180);
  });

  static final plane = picture('ucak', 'Uçak', (b) {
    b.background();
    b.cloud(220, 780, 280);
    b.cloud(790, 170, 240);
    b.poly([170, 480, 120, 290, 270, 450]);
    b.oval(140, 410, 860, 590);
    b.oval(730, 440, 810, 500);
    b.poly([420, 510, 580, 510, 480, 730, 380, 730]);
    b.circle(380, 470, 24);
    b.circle(470, 470, 24);
    b.circle(560, 470, 24);
    b.circle(650, 470, 24);
  });

  static final tree = picture('agac', 'Ağaç', (b) {
    b.background();
    b.circle(860, 140, 80);
    b.rect(0, 820, 1000, 1000);
    b.poly([440, 890, 560, 890, 540, 500, 460, 500]);
    b.union([
      circlePath(500, 320, 200),
      circlePath(330, 440, 140),
      circlePath(670, 440, 140),
      circlePath(500, 510, 140),
    ]);
    b.circle(420, 300, 32);
    b.circle(600, 360, 32);
    b.circle(480, 470, 32);
    b.circle(340, 480, 30);
    b.circle(660, 500, 30);
    b.leaf(150, 830, 120, 760, 160, 700, 190, 770);
    b.leaf(850, 830, 880, 760, 840, 700, 810, 770);
  });

  static final iceCream = picture('dondurma', 'Dondurma', (b) {
    b.background();
    b.poly([370, 560, 630, 560, 500, 930]);
    b.union([
      circlePath(500, 470, 145),
      circlePath(395, 565, 42),
      circlePath(500, 590, 46),
      circlePath(605, 565, 42),
    ]);
    b.circle(500, 290, 125);
    b.circle(500, 150, 42);
    b.line([399, 640, 601, 640]);
    b.line([435, 740, 565, 740]);
    b.line([468, 830, 532, 830]);
    b.line([505, 110, 545, 50]);
  });

  static final cake = picture('pasta', 'Pasta', (b) {
    b.background();
    b.oval(130, 800, 870, 890);
    b.roundRect(220, 560, 780, 835, 20);
    b.union([
      roundRectPath(220, 535, 780, 615, 25),
      circlePath(300, 615, 32),
      circlePath(420, 625, 36),
      circlePath(560, 615, 32),
      circlePath(690, 625, 36),
    ]);
    b.rect(478, 370, 522, 540);
    b.leaf(500, 260, 430, 340, 500, 375, 570, 340);
    b.circle(320, 735, 26);
    b.circle(500, 715, 26);
    b.circle(680, 735, 26);
  });

  static final rocket = picture('roket', 'Roket', (b) {
    b.background();
    b.circle(150, 140, 16);
    b.circle(860, 260, 13);
    b.circle(220, 640, 14);
    b.circle(850, 700, 18);
    b.circle(160, 850, 110);
    b.poly([430, 750, 570, 750, 500, 960]);
    b.poly([460, 750, 540, 750, 500, 880]);
    b.poly([400, 600, 290, 780, 405, 760]);
    b.poly([600, 600, 710, 780, 595, 760]);
    b.union([
      ovalPath(390, 130, 610, 520),
      roundRectPath(390, 330, 610, 770, 30),
    ]);
    b.circle(500, 420, 62);
    b.circle(500, 420, 40);
    b.rect(390, 640, 610, 680);
  });

  static final List<ColoringPicture> all = [
    sun, cat, fish, apple, balloons, flower, butterfly, car, house, //
    rabbit, bird, turtle, boat, plane, tree, iceCream, cake, rocket, //
  ];

  static ColoringPicture? byId(String id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    return null;
  }
}
