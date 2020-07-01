import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stroke_order_animator/strokeOrderAnimationController.dart';

final strokeOrders = [
  "{'strokes': ['M 440 788 Q 497 731 535 718 Q 553 717 562 732 Q 569 748 564 767 Q 546 815 477 828 Q 438 841 421 834 Q 414 831 418 817 Q 421 804 440 788 Z', 'M 532 448 Q 532 547 546 570 Q 559 589 546 601 Q 524 620 486 636 Q 462 645 413 615 Q 371 599 306 589 Q 290 588 299 578 Q 309 568 324 562 Q 343 558 370 565 Q 406 575 441 587 Q 460 594 467 584 Q 473 566 475 538 Q 482 271 470 110 Q 469 80 459 67 Q 453 61 369 82 Q 342 95 344 79 Q 411 27 450 -13 Q 463 -32 480 -38 Q 490 -42 499 -32 Q 541 16 540 77 Q 533 207 532 403 L 532 448 Z', 'M 117 401 Q 104 401 102 392 Q 101 385 117 377 Q 163 352 192 363 Q 309 397 320 395 Q 333 392 323 365 Q 280 256 240 205 Q 200 147 126 86 Q 111 73 122 71 Q 132 70 153 80 Q 220 114 275 172 Q 327 224 394 362 Q 404 384 416 397 Q 431 409 422 419 Q 412 432 374 445 Q 353 455 305 434 Q 215 412 117 401 Z', 'M 567 407 Q 639 452 745 526 Q 767 542 793 552 Q 817 562 806 582 Q 793 601 765 618 Q 740 634 725 632 Q 712 631 715 616 Q 719 582 641 505 Q 601 465 556 420 C 535 399 542 391 567 407 Z', 'M 556 420 Q 543 436 532 448 C 512 470 515 427 532 403 Q 737 114 799 116 Q 871 126 933 135 Q 960 138 960 145 Q 961 152 930 165 Q 777 217 733 253 Q 678 296 567 407 L 556 420 Z'], 'medians': [[[428, 824], [503, 781], [533, 756], [539, 741]], [[309, 579], [358, 580], [462, 613], [482, 608], [508, 581], [505, 121], [500, 59], [478, 24], [355, 78]], [[110, 391], [149, 384], [198, 387], [322, 418], [339, 417], [367, 402], [345, 333], [273, 208], [201, 129], [125, 78]], [[725, 621], [743, 596], [749, 578], [743, 570], [656, 489], [569, 421], [569, 415]], [[532, 441], [551, 399], [568, 378], [678, 259], [750, 194], [801, 163], [954, 145]]], 'radStrokes': [1, 2, 3, 4]}",
  "{'strokes': ['M 272 567 Q 306 613 342 669 Q 370 718 395 743 Q 405 753 400 769 Q 396 782 365 808 Q 337 827 316 828 Q 297 827 305 802 Q 318 769 306 741 Q 267 647 207 560 Q 150 476 72 385 Q 60 375 58 367 Q 54 355 70 358 Q 82 359 109 384 Q 155 421 213 493 Q 226 509 241 527 L 272 567 Z', 'M 241 527 Q 262 506 258 375 Q 258 374 258 370 Q 254 253 221 135 Q 215 114 224 80 Q 236 44 248 32 Q 267 16 279 44 Q 294 86 294 134 Q 303 420 314 485 Q 321 515 295 543 Q 289 549 272 567 C 251 589 227 553 241 527 Z', 'M 521 560 Q 561 621 602 708 Q 620 751 638 773 Q 645 786 639 799 Q 633 811 602 830 Q 572 846 554 843 Q 535 839 546 817 Q 561 795 552 757 Q 513 619 407 448 Q 398 436 397 430 Q 394 418 409 423 Q 439 432 503 532 L 521 560 Z', 'M 503 532 Q 527 510 555 520 Q 795 608 782 549 Q 783 543 743 468 Q 736 458 741 453 Q 745 447 756 459 Q 852 532 894 549 Q 904 552 905 561 Q 906 574 876 592 Q 852 605 828 621 Q 800 637 783 630 Q 686 590 521 560 C 492 555 479 550 503 532 Z', 'M 568 72 Q 531 81 494 91 Q 482 94 483 86 Q 484 79 494 71 Q 569 7 596 -33 Q 611 -49 626 -36 Q 659 -3 661 82 Q 655 149 655 345 Q 656 382 667 407 Q 676 426 659 439 Q 634 461 604 470 Q 585 477 577 469 Q 571 462 582 447 Q 619 384 603 127 Q 597 82 589 74 Q 582 67 568 72 Z', 'M 444 320 Q 419 262 385 208 Q 364 180 381 144 Q 388 128 409 139 Q 460 181 468 264 Q 472 295 467 319 Q 463 328 456 328 Q 449 327 444 320 Z', 'M 738 307 Q 789 249 847 168 Q 860 146 876 139 Q 885 138 893 146 Q 908 159 900 204 Q 891 264 743 338 Q 734 345 731 332 Q 728 319 738 307 Z'], 'medians': [[[317, 812], [342, 786], [353, 759], [303, 663], [249, 577], [181, 485], [93, 386], [68, 367]], [[273, 558], [274, 525], [285, 495], [284, 441], [273, 243], [256, 123], [260, 41]], [[556, 828], [574, 817], [595, 783], [584, 746], [539, 640], [481, 531], [428, 453], [406, 431]], [[513, 532], [704, 585], [796, 597], [813, 585], [827, 563], [798, 519], [746, 460]], [[586, 463], [615, 438], [632, 412], [627, 73], [616, 41], [604, 30], [558, 47], [490, 85]], [[455, 316], [437, 243], [397, 151]], [[742, 326], [812, 265], [856, 216], [871, 190], [878, 154]]], 'radStrokes': [0, 1]}",
  "{'strokes': ['M 309 426 Q 423 471 435 474 Q 448 475 451 481 Q 454 488 445 497 Q 400 530 372 526 Q 366 522 366 514 Q 366 493 247 425 C 221 410 229 398 257 409 Q 264 412 278 416 L 309 426 Z', 'M 247 425 Q 202 446 190 445 Q 172 441 186 423 Q 208 386 196 234 Q 190 195 172 149 Q 154 104 94 43 Q 82 33 79 26 Q 78 20 88 21 Q 115 21 170 75 Q 230 144 246 279 Q 252 366 257 401 Q 258 405 257 409 C 258 420 258 420 247 425 Z', 'M 405 168 Q 339 128 335 128 Q 331 131 329 144 Q 332 333 341 380 Q 345 396 334 406 Q 321 419 309 426 C 284 443 260 440 278 416 Q 299 395 297 354 Q 301 191 290 135 Q 286 110 276 95 Q 266 76 274 58 Q 284 30 300 21 Q 310 14 319 31 Q 340 64 414 153 C 433 176 431 184 405 168 Z', 'M 414 153 Q 421 140 434 137 Q 443 134 451 146 Q 454 155 451 171 Q 447 187 429 200 Q 402 222 389 229 Q 383 232 380 223 Q 377 214 405 168 L 414 153 Z', 'M 372 332 Q 403 298 439 248 Q 449 233 460 229 Q 467 228 473 234 Q 483 243 476 275 Q 473 305 423 331 Q 392 347 374 354 Q 368 358 366 350 Q 365 340 372 332 Z', 'M 615 462 Q 684 489 722 496 Q 735 496 739 503 Q 742 510 732 520 Q 687 557 657 553 Q 651 550 650 541 Q 650 519 541 461 C 515 447 522 436 551 445 Q 563 449 581 453 L 615 462 Z', 'M 541 461 Q 540 462 537 463 Q 494 482 482 478 Q 466 474 480 456 Q 513 410 500 232 Q 494 186 476 130 Q 458 78 389 -1 Q 377 -13 375 -18 Q 374 -24 384 -23 Q 418 -20 472 45 Q 544 138 549 345 Q 546 408 551 438 Q 551 442 551 445 C 552 456 552 456 541 461 Z', 'M 639 413 Q 640 417 641 420 Q 645 436 634 446 Q 624 456 615 462 C 592 481 569 481 581 453 Q 580 453 581 452 Q 597 421 597 394 Q 601 183 586 111 Q 582 86 572 71 Q 562 53 569 34 Q 579 6 594 -3 Q 604 -10 614 7 Q 638 41 719 131 C 739 153 736 163 710 147 Q 637 102 632 103 Q 626 106 625 120 Q 628 325 637 398 L 639 413 Z', 'M 719 131 Q 746 80 756 76 Q 763 75 770 81 Q 777 90 778 111 Q 779 145 706 200 Q 697 206 692 206 Q 688 205 686 196 Q 686 190 710 147 L 719 131 Z', 'M 637 398 Q 662 379 679 350 Q 757 218 821 126 Q 833 108 855 106 Q 936 102 967 104 Q 980 104 986 110 Q 990 114 982 119 Q 865 177 829 213 Q 768 271 682 395 Q 675 411 660 413 Q 644 416 639 413 C 621 412 621 412 637 398 Z'], 'medians': [[[443, 485], [391, 492], [316, 444], [263, 426], [259, 416]], [[191, 433], [211, 419], [226, 397], [221, 254], [212, 204], [193, 147], [167, 101], [115, 45], [86, 27]], [[284, 414], [310, 403], [318, 388], [310, 123], [320, 94], [367, 123], [399, 151], [397, 158]], [[388, 220], [427, 174], [437, 152]], [[373, 346], [448, 280], [462, 244]], [[731, 507], [676, 518], [617, 482], [570, 461], [557, 461], [556, 454]], [[484, 467], [521, 435], [527, 316], [514, 194], [495, 124], [461, 60], [415, 6], [381, -17]], [[587, 453], [617, 428], [612, 175], [606, 121], [614, 69], [658, 92], [702, 130], [701, 137]], [[696, 197], [751, 123], [760, 86]], [[645, 405], [661, 398], [677, 379], [773, 239], [847, 152], [866, 140], [979, 112]]], 'radStrokes': [0, 1, 2, 3, 4]}",
  "{'strokes': ['M 407 333 Q 417 358 430 381 Q 464 460 477 550 L 482 584 Q 500 716 521 761 Q 531 783 512 792 Q 458 831 426 820 Q 410 814 419 797 Q 450 740 428 571 L 421 534 Q 394 420 360 355 L 339 317 Q 324 295 309 271 Q 266 208 186 147 Q 167 131 141 114 Q 125 101 107 87 Q 92 75 106 73 Q 122 73 162 90 Q 243 130 302 190 Q 350 235 380 282 L 407 333 Z', 'M 477 550 Q 544 572 594 579 Q 616 583 622 578 Q 626 571 621 554 Q 497 139 642 65 Q 678 44 746 35 Q 884 22 968 74 Q 987 84 980 107 Q 964 165 961 251 Q 960 270 954 269 Q 948 270 942 251 Q 908 149 879 125 Q 861 109 804 103 Q 740 96 687 113 Q 642 128 628 160 Q 606 200 615 289 Q 628 386 674 503 Q 693 554 726 581 Q 742 594 741 607 Q 740 619 670 651 Q 655 661 637 646 Q 588 612 505 591 Q 493 588 482 584 L 428 571 Q 367 558 308 541 Q 262 531 188 530 Q 173 531 176 516 Q 179 503 206 487 Q 237 469 275 485 Q 354 513 421 534 L 477 550 Z', 'M 380 282 Q 455 216 463 214 Q 470 213 477 222 Q 487 235 473 272 Q 463 306 407 333 L 360 355 Q 312 379 284 389 Q 277 393 275 382 Q 275 370 285 361 Q 310 342 339 317 L 380 282 Z'], 'medians': [[[429, 806], [450, 794], [475, 764], [448, 530], [409, 398], [354, 291], [303, 223], [214, 142], [110, 80]], [[185, 520], [222, 506], [259, 507], [619, 606], [661, 605], [669, 595], [661, 560], [631, 482], [602, 369], [588, 274], [588, 225], [596, 172], [612, 133], [639, 102], [671, 85], [741, 68], [807, 67], [889, 83], [920, 100], [931, 115], [953, 263]], [[285, 378], [425, 285], [452, 256], [465, 222]]], 'radStrokes': [2]}",
  "{'strokes': ['M 520 564 Q 643 660 682 671 Q 704 678 697 695 Q 694 711 626 752 Q 607 764 582 755 Q 512 731 408 705 Q 381 698 315 701 Q 290 702 299 681 Q 306 668 326 655 Q 359 636 394 656 Q 421 665 555 707 Q 568 713 581 705 Q 593 696 587 683 Q 551 634 509 576 C 491 552 496 546 520 564 Z', 'M 558 230 Q 576 363 550 493 Q 541 533 520 564 L 509 576 Q 499 589 483 596 Q 473 603 467 595 Q 463 591 470 577 Q 525 462 507 297 Q 504 291 504 283 Q 495 216 462 211 Q 456 211 451 211 Q 376 221 368 216 Q 364 215 380 203 Q 441 160 477 121 Q 496 105 513 114 Q 541 132 556 220 L 558 230 Z', 'M 231 429 Q 219 435 189 441 Q 176 445 173 439 Q 166 433 175 417 Q 200 363 214 276 Q 217 249 232 232 Q 250 210 255 225 Q 259 238 259 262 L 255 293 Q 243 378 243 403 C 242 424 242 424 231 429 Z', 'M 386 317 Q 399 389 420 411 Q 441 436 418 449 Q 399 459 374 474 Q 355 483 338 472 Q 310 451 231 429 C 202 421 214 396 243 403 Q 282 413 322 424 Q 341 428 347 421 Q 354 417 349 386 Q 345 355 338 318 C 333 289 380 288 386 317 Z', 'M 259 262 Q 266 261 277 264 Q 314 274 399 287 Q 409 288 409 297 Q 409 304 386 317 C 372 325 367 324 338 318 Q 337 318 336 318 Q 290 302 255 293 C 226 285 229 263 259 262 Z', 'M 753 317 Q 781 363 808 434 Q 818 461 836 478 Q 852 493 840 504 Q 828 514 799 524 Q 777 531 753 517 Q 729 507 697 495 Q 666 485 610 476 Q 597 475 593 468 Q 590 461 607 455 Q 641 443 687 458 Q 729 477 737 477 Q 759 477 756 453 Q 743 389 718 346 Q 715 342 713 338 L 686 303 Q 638 257 559 231 Q 558 231 558 230 C 544 224 544 224 556 220 Q 584 199 676 246 Q 677 249 682 250 Q 701 262 718 277 L 753 317 Z', 'M 718 277 Q 832 187 836 186 Q 843 185 849 194 Q 858 207 843 242 Q 833 275 753 317 L 713 338 Q 643 374 603 389 Q 596 393 595 382 Q 595 370 605 363 Q 644 336 686 303 L 718 277 Z', 'M 516 38 Q 565 39 611 43 Q 750 52 863 33 Q 890 29 896 39 Q 906 54 892 68 Q 817 140 757 120 Q 379 71 165 70 Q 159 70 153 70 Q 137 70 136 58 Q 135 43 155 27 Q 174 12 209 -2 Q 221 -6 241 2 Q 334 27 516 38 Z'], 'medians': [[[309, 689], [333, 677], [359, 673], [570, 730], [607, 725], [633, 697], [541, 593], [525, 578], [518, 579]], [[475, 590], [512, 534], [536, 421], [536, 302], [521, 216], [495, 172], [461, 179], [371, 215]], [[182, 431], [214, 398], [244, 231]], [[242, 426], [251, 420], [348, 449], [377, 435], [385, 426], [366, 341], [344, 324]], [[263, 270], [274, 281], [335, 297], [399, 297]], [[600, 466], [662, 468], [740, 494], [773, 494], [790, 485], [785, 451], [760, 379], [737, 333], [700, 287], [638, 245], [563, 224]], [[605, 379], [780, 267], [813, 239], [840, 195]], [[150, 56], [175, 44], [224, 34], [369, 53], [779, 84], [824, 76], [881, 51]]]}",
  "{'strokes': ['M 326 667 Q 283 663 312 640 Q 369 610 428 623 Q 543 641 665 661 Q 720 671 729 678 Q 739 688 735 698 Q 728 711 693 722 Q 660 731 561 701 Q 420 673 326 667 Z', 'M 329 421 Q 304 417 332 392 Q 348 379 385 383 Q 557 405 685 416 Q 721 420 709 440 Q 694 462 657 472 Q 621 479 558 466 Q 435 441 329 421 Z', 'M 130 165 Q 102 162 122 139 Q 140 120 163 113 Q 191 104 212 110 Q 515 179 929 157 Q 930 158 933 157 Q 960 156 967 167 Q 974 183 953 201 Q 884 255 835 246 Q 643 210 130 165 Z'], 'medians': [[[316, 655], [367, 645], [416, 648], [660, 692], [722, 692]], [[331, 407], [375, 405], [628, 443], [657, 443], [700, 432]], [[127, 152], [158, 142], [195, 139], [500, 178], [846, 204], [881, 200], [955, 174]]], 'radStrokes': [0]}"
];

void main() {
  final tickerProvider = TestVSync();
  debugSemanticsDisableAnimations = true;

  test("Test stroke count", () {
    final controllers = List.generate(
      strokeOrders.length,
      (index) =>
          StrokeOrderAnimationController(strokeOrders[index], tickerProvider),
    );

    expect(controllers[0].nStrokes, 5);
    expect(controllers[1].nStrokes, 7);
    expect(controllers[2].nStrokes, 10);
    expect(controllers[3].nStrokes, 3);
    expect(controllers[4].nStrokes, 8);
    expect(controllers[5].nStrokes, 3);
  });

  group("Test animation controls", () {
    final controller =
        StrokeOrderAnimationController(strokeOrders[0], tickerProvider);

    test('Next stroke', () {
      controller.reset();
      controller.nextStroke();
      controller.nextStroke();
      expect(controller.currentStroke, 2);
    });

    test('Previous stroke', () {
      controller.reset();
      controller.nextStroke();
      controller.nextStroke();
      controller.previousStroke();
      expect(controller.currentStroke, 1);
    });

    test('Show full character', () {
      controller.showFullCharacter();
      expect(controller.currentStroke, controller.nStrokes);
      expect(controller.currentStroke, 5);
    });

    test('Reset', () {
      controller.reset();
      expect(controller.currentStroke, 0);
      controller.nextStroke();
      controller.reset();
      expect(controller.currentStroke, 0);
    });
  });

  group('Test quizzing', () {
    final controller =
        StrokeOrderAnimationController(strokeOrders[0], tickerProvider);

    final wrongStroke0 = [Offset(0, 0), Offset(10, 10)];
    final correctStroke0 = [Offset(430, 80), Offset(540, 160)];
    final inverseStroke0 = [Offset(540, 160), Offset(430, 80)];

    final controller2 =
        StrokeOrderAnimationController(strokeOrders[1], tickerProvider);

    test('Start quiz', () {
      controller.startQuiz();
      controller.reset();
      expect(controller.isQuizzing, true);
      expect(controller.isAnimating, false);
      expect(controller.currentStroke, 0);
    });

    group('Check stroke', () {
      controller.startQuiz();

      test('Empty stroke does not lead to crash', () {
        controller.checkStroke([]);
      });

      test('Correct stroke gets accepted', () {
        controller.checkStroke(correctStroke0);
        expect(controller.currentStroke, 1);
      });

      test('Wrong stroke does not get accepted', () {
        controller.reset();
        controller.checkStroke(wrongStroke0);
        expect(controller.currentStroke, 0);
      });

      test('Inverse stroke does not get accepted', () {
        controller.reset();
        controller.checkStroke(inverseStroke0);
        expect(controller.currentStroke, 0);
      });
    });

    group('Quiz summary', () {
      controller.startQuiz();

      test('Summary is initially empty', () {
        controller.reset();
        controller2.reset();
        expect(controller.summary.nStrokes, 5);
        expect(controller2.summary.nStrokes, 7);
        expect(controller.summary.nTotalMistakes, 0);
        expect(controller.summary.mistakes[0], 0);
        expect(controller.summary.mistakes[4], 0);
      });

      test('Wrong stroke increases number of total mistakes', () {
        controller.reset();
        controller.checkStroke(wrongStroke0);
        expect(controller.summary.nTotalMistakes, 1);
        controller.checkStroke(wrongStroke0);
        expect(controller.summary.nTotalMistakes, 2);
      });

      test('Reset resets number of single and total mistakes', () {
        controller.checkStroke(wrongStroke0);
        controller.reset();
        expect(controller.summary.nTotalMistakes, 0);
        for (var nMistakes in controller.summary.mistakes) {
          expect(nMistakes, 0);
        }
      });

      test('Mistakes get counted separately for each stroke', () {
        controller.reset();
        controller.checkStroke(wrongStroke0);
        expect(controller.summary.mistakes[0], 1);

        controller.checkStroke(correctStroke0);
        controller.checkStroke(wrongStroke0);
        controller.checkStroke(wrongStroke0);
        expect(controller.summary.mistakes[0], 1);
        expect(controller.summary.mistakes[1], 2);
      });

      test('Summary gets reset when quiz starts', () {
        controller.reset();
        controller.checkStroke(wrongStroke0);
        controller.stopQuiz();
        controller.startQuiz();
        expect(controller.summary.nTotalMistakes, 0);
      });
    });

    group('Callbacks', () {
      final controller =
        StrokeOrderAnimationController(strokeOrders[5], tickerProvider);

      final correctStroke0 = [Offset(316, 245), Offset(722, 208)];
      final correctStroke1 = [Offset(331, 493), Offset(700, 468)];
      final correctStroke2 = [Offset(127, 748), Offset(955, 726)];

      QuizSummary summary1;
      int nCalledOnQuizComplete1 = 0;

      final onQuizComplete1 = (summary) {
        summary1 = summary;
        nCalledOnQuizComplete1++;
      };

      controller.addOnQuizCompleteCallback(onQuizComplete1);

      test('Summary gets passed to callback when quiz finishes', () {
        nCalledOnQuizComplete1 = 0;
        controller.startQuiz();
        controller.checkStroke(correctStroke0);
        controller.checkStroke(correctStroke1);
        controller.checkStroke(correctStroke2);
        expect(nCalledOnQuizComplete1, 1);
      });

      test('Summary passed to callback contains correct mistakes information', () {
        controller.startQuiz();
        controller.checkStroke(correctStroke0);
        controller.checkStroke(wrongStroke0);
        controller.checkStroke(wrongStroke0);
        controller.checkStroke(correctStroke1);
        controller.checkStroke(wrongStroke0);
        controller.checkStroke(correctStroke2);
        expect(summary1.nTotalMistakes, 3);
        expect(summary1.mistakes[0], 0);
        expect(summary1.mistakes[1], 2);
        expect(summary1.mistakes[2], 1);
      });

      test('Summary gets passed to additional callback', () {
        QuizSummary summary2;
        int nCalledOnQuizComplete2 = 0;

        final onQuizComplete2 = (summary) {
          summary2 = summary;
          nCalledOnQuizComplete2++;
        };

        controller.addOnQuizCompleteCallback(onQuizComplete2);

        controller.startQuiz();
        controller.checkStroke(correctStroke0);
        controller.checkStroke(wrongStroke0);
        controller.checkStroke(wrongStroke0);
        controller.checkStroke(correctStroke1);
        controller.checkStroke(wrongStroke0);
        controller.checkStroke(correctStroke2);

        expect(nCalledOnQuizComplete2, 1);
        expect(summary1.nTotalMistakes, summary2.nTotalMistakes);
        expect(summary1.mistakes[0], summary2.mistakes[0]);
        expect(summary1.mistakes[1], summary2.mistakes[1]);
        expect(summary1.mistakes[2], summary2.mistakes[2]);
      });
    });
  });
}
