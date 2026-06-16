# Differential Privacy & Zero-Knowledge Proofs

This document will contain the formal mathematical definitions and proofs for the DP-SGD noise addition and the ZKP circuits used for update verification.

## Differential Privacy via Opacus and Custom Fallback
FusionNet utilizes an abstract DP-SGD engine. By default, it uses the PyTorch `opacus` library to guarantee mathematical correctness of the Differential Privacy implementation. `opacus` provides an automated mechanism to wrap the optimizer and dataloader, ensuring that per-sample gradient norms are strictly clipped to $C$ and that calibrated Gaussian noise $N(0, \sigma^2)$ is added to the averaged gradients.

Because 4-bit quantization via `bitsandbytes` can sometimes cause internal hook errors within `opacus`, FusionNet automatically drops down to an equivalent **Custom Privacy Engine** if initialization fails. This custom engine strictly enforces identical per-sample gradient clipping norms and calculates the same noise multipliers using the formula:
$\sigma = \frac{C \sqrt{2 \ln(1.25/\delta)}}{\epsilon}$
