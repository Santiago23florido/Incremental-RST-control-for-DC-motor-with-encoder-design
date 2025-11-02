# Digital RST Control for DC Motor with Encoder Feedback

This repository contains the implementation, simulation, and testing of a digital RST controller applied to a DC motor with incremental encoder feedback. The work includes experimental system identification, controller design in discrete time, closed-loop simulation in MATLAB/Simulink, and performance evaluation under multiple operating conditions.

## Overview

The RST controller distributes control objectives across three discrete-time polynomials:

- **R(z):** Feedback and stabilization
- **S(z):** Disturbance attenuation and noise shaping
- **T(z):** Reference trajectory shaping

The controller is implemented in incremental form to increase numerical stability and reduce sensitivity to measurement noise.

## Requirements

- MATLAB R2021a or later
- Simulink
- Control System Toolbox

## Usage

1. Run the scripts in `identification/` to obtain the motor model.
2. Design and configure the RST controller in `control/`.
3. Open and simulate closed-loop performance using the models in `simuls/`.
4. Use the scripts in `response/` for performance analysis and validation.

## Author

Santiago Florido  
Mechatronics Engineering
