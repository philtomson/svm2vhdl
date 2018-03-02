Code Archeology

Way back in 2005 I did a research fellowship at the University of Genoa in Italy.

My research project was to implement a trained Support Vector Machine (SVM) in an FPGA. I recycled the project and added some features (and fixed some bugs) for an ECE590 class at PSU the same year - I think the title of the class was something like Highlevel Modeling for FPGA Development or some such.

This was one of the more intersting projects I've done. It's on my resume and when interviewers ask about interesting projects I usually bring this one up. This is why I wanted to dig up the project and put it on github. Unfortunately, the laptop I developed it on way back then has been long dead. However, I tend not to throw anything away and so I found that I had sent the tar file to my ECE590 professor way back in June of 2005. Unfortunately, the later work I did to fix the testbench problem noted in the "Testbench and Verification results" section of the project report (see: project/ECE590_lab3_report.pdf) was on that dead laptop, so what is here on github does not represent the final form of the code, unfortunately. But most of it is here and several of the testbenches do work. (In my sleuthing I found an email in response to my professor several months later where I sent him the working testbench along with the rest of the VHDL files after he asked about using it for an example.)

What's an SVM?:

A machine learning technique that was popular prior to the re-emergence of Neural Network popularity starting around 2006.

What's here:

I wrote several ruby scripts to model the SVM at different levels of accuracy using fixed point math. That way I could reduce the number of bits of precision until to figure out the minimum size to get results as good as the original "golden" C implementation. It looks like I got it to 16 bits. One of the ruby scripts generates a lookup table for the guassian kernel. I could vary the size of the table (the resolution) to determine the smallest table that would give good results. It turns out I only needed a table with 128 entries. 

The main script at aaa2vhdl/TESTS/run_banana_vhdl.rb can be run to generate all of the vhdl files for the design.

More info in the docs directory (SVM_pres.html) as well as in aaa2vhdl/DOCS. The final project report in project/ECE590_lab3_report.pdf offers a good overview as well as synthesis results, utilization and performance numbers.

What's not here:

I don't see the original C code - it certainly looks like aaa2vhdl/banana.cpp is part of that, however it has no main function and in the mists of time I can't recall quite how that was supposed to work. However, there is a highlevel Ruby implementation that does exactly what the C "golden" implementation did (just a lot slower).

Requirements:
* Ruby
* ghdl (free VHDL simulator)

To run: 

go to aaa2vhdl/TESTS:
$ ruby run_banana_vhdl.rb

You'll see several .vhd files get generated there in TESTS. Consult the final report for what each one does.
