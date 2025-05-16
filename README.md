Our first idea for EDA project. The concept was to use FFT(fast fourier transformation) to recognize played note(even two or more notes! but more on that later). 

Why?
Zero crossing alogithms only pro is its simplicity. Much more cons on the other side: can't recognize more than 1 note, is vulnerable to noise => requires filtering(yuck).

FFT on the other hand solves both of that problems, in exchange of memory and much more computational logic.
What it does? If we give it 2^n microphone inputs(128 in our case), it will return 2^n bins, where amplitudes of corresponding frequency is contained(how much of each frequency you had in you microphone input).
For example bin[1] contains amplitude of 20 Hz, bin[5] = amplitude of 70 Hz, etc.
If we play two notes together, it will tell us which frequencies had amplitude, and by simple calculations on that data, we can determine the notes played.

The idea of project was to draw the chord(contains 3 notes) played on guitar and draw it like we draw on our second project(green strings).

Why we left this project?
Maybe FFT implementation is wrong, or we didn't fully understand it's logic. Even on testbenches all FFT outputs bins had almost maximum amplitude. It makes impossible to recognize anything. Implementation
is taken from someone's github. We will not give him any credits, because our project failed. all his fault >:(
