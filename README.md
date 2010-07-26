TimeLapse Controller
====================
This project provides the code for building a time lapse intervalometer by means of an [arduino board]("http://arduino.cc" Arduino website).

At the moment, I developed and only tested the code on Arduino Mega board, although it doesn't need the extra bunch of pins that the Mega has over a plain old Arduino Duemilanove or Diecimila. I only had a Mega and a Mega protoshield when I started the project!

The interface with your dSLR camera is the standard 2.5mm TRS jack (tested on Pentax and Canon dSLRs).

*I plan to add pictures and board sketches here soon, so stay tuned, or ask me directly if you're eager to know more!*

Functionalities
---------------
The current version has the following functionalities:

1. programmable shoot period, from as low as 1s up to 59m 59s
2. programmable number of shots, from 0 (which means unlimited) up to 9999 shots
3. programmable start delay: the shooting sequence start can be delayed from 0m (immediate) to 24h
