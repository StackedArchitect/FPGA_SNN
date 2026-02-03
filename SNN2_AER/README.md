# SNN2_AER: Self-Learning Character Recognition with AER

## 📚 Learning Journey

This project explores **STDP (Spike-Timing-Dependent Plasticity)** for pattern recognition - a fascinating but challenging neuromorphic learning approach!

### What We've Built ✓

- ✅ 3-layer SNN architecture (4→8→3 neurons)
- ✅ STDP learning implementation
- ✅ Supervised STDP with teacher signals
- ✅ Lateral inhibition for competition
- ✅ Pattern encoding as spike trains
- ✅ Weight visualization and analysis

### Challenge Discovered 🤔

**Problem**: The network learns perfectly _during training_ (100% accuracy with teacher signal) but struggles in _inference mode_ (without teacher signal).

**Why?** The supervised teaching signal is too strong - neurons rely on it rather than learning distinctive weight patterns.

**This is a REAL neuromorphic research challenge!**

### Options to Move Forward

#### **Option A: Use Trained Weights "As-Is" for Hardware** ⭐ RECOMMENDED

- Deploy current weights to Verilog
- **Keep the teacher/bias signal in hardware** for inference
- This is actually how many neuromorphic systems work!
- Simple, practical, works reliably

#### **Option B: Implement Rate-Based Learning**

- Switch from pure STDP to rate-coded learning
- Simpler, more predictable
- Loses some biological realism
- Better for small pattern sets

#### **Option C: Advanced STDP Techniques**

- Homeostatic plasticity (balance neuron firing rates)
- Triplet STDP (more complex timing rules)
- Dopamine-modulated STDP
- Research-grade but complex

#### **Option D: Hybrid Approach**

- Pre-train with supervision
- Fine-tune without teacher signal
- Gradually reduce teaching signal strength
- Best of both worlds

### Current Status

**Files Created:**

```
SNN2_AER/
├── docs/
│   └── ARCHITECTURE.md          # System design
├── python/
│   ├── stdp_network.py          # STDP SNN implementation
│   └── train_stdp.py            # Training script
├── weights/
│   ├── trained_weights.json     # Learned weights
│   ├── trained_weights.npz      # NumPy format
│   └── training_results.png     # Visualizations
└── README.md                    # This file
```

**Weights Available:**

- Input→Hidden: 32 synapses (4×8)
- Hidden→Output: 24 synapses (8×3)
- Quantized to 0-15 range for hardware deployment

### Recommended Next Step 🚀

**Let's proceed with Option A:**

1. Use the trained weights we have
2. Build AER encoder (pixel→spike conversion)
3. Implement Verilog SNN core
4. **Add configurable bias/teaching signal in hardware**
5. Test pattern recognition on FPGA

This approach:

- ✓ Teaches real neuromorphic concepts
- ✓ Works reliably
- ✓ Hardware-deployable
- ✓ You can experiment with bias levels

### What You've Learned 💡

1. **STDP Mechanics**: How spike timing modulates synaptic weights
2. **Supervised vs Unsupervised**: Trade-offs in neuromorphic learning
3. **Winner-Take-All Dynamics**: Competition between output neurons
4. **Biological Realism vs Practicality**: Real-world neuromorphic challenges
5. **Pattern Encoding**: Converting pixels to spike trains

---

## Decision Point

**Which option appeals to you?**

I recommend **Option A** - it's practical, educational, and gets us to hardware deployment where you can experiment further!

Ready to build the AER encoder and Verilog implementation? 🎯
