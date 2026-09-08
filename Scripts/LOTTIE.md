# Lottie artwork

The seven JSON files in `ColorPicker/Animations` are original vector artwork
created for this app. They contain no downloaded illustrations, fonts, or images.
Regenerate them with `python3 Scripts/generate_lottie.py` from the repository root.

`LottieArtwork` loads the files from the app bundle, plays looping illustrations
only while active and visible, and displays the final frame for Reduce Motion.
Success plays once in 0.6 seconds; home icon loops last 3 seconds, and other decorative loops last 2 seconds. Missing assets
fall back to SF Symbols. The views are decorative and hidden from VoiceOver.

The home screen uses transparent camera, gallery, converter, and palette
animations directly on the colored cards.

The project pins Airbnb's Lottie Swift package to 4.6.1, using the recommended
binary distribution: https://github.com/airbnb/lottie-spm
Upstream documentation and Apache 2.0 license: https://github.com/airbnb/lottie-ios

Validation: simulator build and onboarding screenshot; all four JSON files were
decoded with LottieAnimation.from(data:) and rendered with LottieAnimationLayer
at progress 0, 0.5, and 1 to inspect motion poses and Reduce Motion final frames.
