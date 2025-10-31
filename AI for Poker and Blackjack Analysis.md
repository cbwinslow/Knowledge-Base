1

# **An Expert Report on the Design and Implementation of a Vision-Based AI Agent for Strategic Poker and Blackjack Play**

## **Section 1: The Perception Layer: A Vision-Based Framework for Game State Comprehension**

The foundational layer of any AI agent designed to interact with a graphical user interface is its perception system. This system is responsible for the critical task of translating raw pixel data from a computer screen into a structured, machine-readable representation of the game state. For card games like poker and blackjack, this involves two primary challenges: the identification and classification of physical game elements like cards and chips, and the extraction of textual information such as bet sizes, pot totals, and player actions. This section details a robust, multi-modal perception framework, analyzing state-of-the-art computer vision models for object detection and optical character recognition (OCR) to build a comprehensive understanding of the game environment.

### **1.1 High-Fidelity Card and Chip Detection with Convolutional Neural Networks**

The accurate and rapid detection of playing cards is the most crucial perceptual task. The agent's entire strategic analysis depends on a correct reading of its own hand, the community cards, and any visible opponent cards. For this task, the YOLO (You Only Look Once) family of object detection models stands out as the premier choice due to its exceptional balance of speed and accuracy, making it ideal for real-time applications.1

#### **Core Technology Selection and Performance**

The research indicates that several versions of the YOLO architecture are highly effective for playing card detection.

* **YOLOv8:** As the most recent iteration discussed, YOLOv8 demonstrates state-of-the-art performance. In a project specifically designed for playing card detection, a trained yolov8s model achieved a mean Average Precision (mAP) at an Intersection over Union (IoU) threshold of 0.50 (mAP50) of 0.995. A more stringent metric, mAP50-95 (averaging mAP over IoU thresholds from 0.50 to 0.95), was an impressive 0.957. This level of accuracy is achieved with a compact model size of just 22.0MB, making it efficient to run even on systems without high-end GPUs.2  
* **Other YOLO Variants:** The success of this architecture is not limited to its latest version. A project utilizing a model referred to as "YOLO11" (plausibly a custom-trained or newer variant of the YOLO family) also reported a mAP50 of 0.995 on a dataset from the Roboflow platform. This project provides valuable performance benchmarks, noting an inference time of approximately 160ms on a 3.4GHz CPU, which is well within the acceptable limits for real-time decision-making in a turn-based card game.3 Even older versions like YOLOv4 have been successfully applied, though they required more extensive training, often over 1000 epochs, to achieve robustness against cluttered backgrounds and varied card orientations.1

#### **Implementation Guide**

Implementing a custom YOLO detector for playing cards follows a standardized machine learning pipeline:

1. **Data Collection and Annotation:** A high-quality dataset is paramount. Publicly available datasets, such as those on Roboflow, provide an excellent starting point.3 For a custom application, images of the specific game client should be captured. These images must then be annotated, a process where bounding boxes are drawn around each card and assigned a class label (e.g., 'KH' for King of Hearts, '7C' for 7 of Clubs). Tools like labelImg are commonly used for this purpose, generating text files that store the class and coordinate information for each label in the format required by YOLO.1 The dataset should be split into training, validation, and testing sets.  
2. **Training Configuration:** The training process is typically configured using a YAML file. This file specifies the paths to the training and validation image sets and lists the class names corresponding to the 52 cards in a deck. The structure is standardized across recent YOLO versions, simplifying the setup process.2  
3. **Model Training:** Training is initiated via a command-line interface, specifying the model to use (e.g., yolov8s.pt for a small, pre-trained model), the path to the data configuration file, and hyperparameters like the number of epochs and batch size. Training for as few as 10 epochs can yield extremely high accuracy on a well-prepared dataset.2  
4. **Inference:** Once trained, the model can be deployed for inference. The agent's perception loop will capture a screenshot of the game area, pass it to the trained YOLO model, and receive a list of detected cards and their bounding box coordinates. This structured data is the primary input for the game state tracker and strategic core.2

#### **Alternative and Supplementary Models**

While YOLO provides a powerful and streamlined solution, a production-grade system should account for potential failure modes. A recent study on poker game state detection found that while their fine-tuned YOLOv8 model achieved over 99% accuracy in testing, it "often misread some cards and made the game state incorrect" during practical application.4 This highlights a critical gap between benchmark performance and real-world robustness.

To mitigate this, a hybrid approach offers superior resilience. This involves using a transformer-based, prompt-driven object detection model like **GroundingDINO**.4 Instead of being trained on a fixed set of classes, GroundingDINO can locate objects based on textual prompts like "playing card." The regions identified by GroundingDINO are then passed to a dedicated, highly specialized Convolutional Neural Network (CNN) trained solely for card classification. This two-stage process—general detection followed by specialized classification—proved more reliable in practice than a single end-to-end model, providing a valuable architectural alternative or a fallback mechanism for when the primary YOLO detector fails to yield a confident result.4

### **1.2 Deconstructing the UI: Text and Data Extraction with OCR**

Beyond identifying cards, the agent must read crucial numerical and textual data from the game's user interface. Pot sizes, player stack sizes, bet amounts, and action logs (e.g., "Player A raises to $50") are all rendered as text. An Optical Character Recognition (OCR) engine is required to parse this information. The choice of OCR engine is critical, as game UIs can feature stylized fonts, varied backgrounds, and dynamic elements that challenge traditional OCR systems.

#### **Comparative Analysis of OCR Engines**

The open-source landscape offers two primary contenders for this task: Tesseract and EasyOCR.

* **Tesseract:** Developed by Hewlett-Packard and later Google, Tesseract is one of the most established and widely used OCR engines.5 Its primary strength lies in processing "nice clean text," similar to that found in scanned documents. It supports over 100 languages and offers extensive configuration options through wrappers like pytesseract, allowing users to fine-tune its performance for specific fonts and layouts.5 For a game client with a very clean, standardized, and high-contrast UI, Tesseract can be a powerful and accurate option.  
* **EasyOCR:** A more modern alternative, EasyOCR is built on deep learning techniques and is packaged as a user-friendly Python library.5 Its defining advantage is its superior performance on "text-in-the-wild." This refers to text found in real-world scenes, which is often subject to noise, distortion, low resolution, and complex backgrounds.5 The visual environment of a game UI, with its graphical flourishes and potential for overlapping elements, more closely resembles "text-in-the-wild" than a scanned document. EasyOCR's deep learning foundation makes it inherently more robust to these variations, and it is often simpler to integrate into a Python application with fewer dependencies.5

#### **Decision Framework and Recommendation**

The selection between Tesseract and EasyOCR depends on the desired scope of the AI agent. If the agent is designed to target a single, specific online poker client with a known, clean UI, fine-tuning Tesseract on the game's specific fonts could yield excellent results.

However, for a more general-purpose agent intended to work across multiple game platforms with diverse and unpredictable graphical styles, **EasyOCR is the superior choice**. Its demonstrated robustness on noisy and distorted images makes it far more likely to maintain high accuracy without platform-specific tuning.5 This adaptability is crucial for a scalable and resilient perception system.

The perception layer, while foundational, is not a perfectly reliable oracle. The fact that a YOLOv8 model with 99%+ test accuracy can still make critical errors in a live environment is a profound finding.4 This introduces a layer of uncertainty at the very root of the agent's world model. A game like Blackjack is, in theory, a game of perfect information once the cards are known. However, if the perception system has a non-zero error rate, the agent can never be 100% certain of the true game state. It might "see" a 5 but have to contend with a small probability that the card is actually a 6 or an 8\. This fundamentally changes the nature of the problem. The agent is no longer operating in a fully observable world. Instead, its "observation" is the potentially flawed output of the vision models. This implies that a truly advanced agent cannot treat the perception output as ground truth. It must model the uncertainty of its own perception, transforming the decision-making problem from a simple Markov Decision Process into a more complex Partially Observable Markov Decision Process, where the belief state must account for the probability of a visual misinterpretation. This connection between the vision system's fallibility and the required sophistication of the core AI framework will be explored further in Section 3\.

### **Table 1: Comparison of Computer Vision and OCR Technologies for Game State Analysis**

| Model/Library | Primary Task | Key Architecture | Performance Metrics | Strengths | Weaknesses/Considerations | Recommended Use Case |
| :---- | :---- | :---- | :---- | :---- | :---- | :---- |
| **YOLOv8** | Object Detection | CNN | mAP50: 0.995 2 | High accuracy, real-time speed, small model size (22.0MB), well-documented training pipeline. | Can misread cards in practice despite high test accuracy.4 | Primary real-time detector for cards and chips in a known game environment. |
| **GroundingDINO \+ CNN** | Object Detection & Classification | Transformer \+ CNN | High practical robustness 4 | Excellent at detecting objects in novel scenes without specific training; two-stage process is more robust to variations. | Higher implementation complexity; two-model pipeline may be slower than end-to-end YOLO. | A fallback system for YOLO or the primary system in environments with highly variable visual styles. |
| **Tesseract** | OCR | Traditional CV \+ LSTM | High accuracy on clean text | Excellent for high-quality, document-like text; highly customizable; supports 100+ languages.5 | Performs poorly on noisy, stylized, or low-resolution text common in game UIs.7 | Dedicated agent for a single game client with a known, clean, high-contrast UI. |
| **EasyOCR** | OCR | Deep Learning (CNN+RNN) | High accuracy on "text-in-the-wild" | Robust to noise, distortion, and varied fonts; simple Python API; supports 80+ languages.5 | May be slightly slower than Tesseract on CPU for very clean text.6 | General-purpose agent designed to work across multiple game clients with diverse visual designs. |

## **Section 2: Algorithmic Strategy for Deterministic and Probabilistic Games**

With a structured representation of the game state provided by the perception layer, the agent must now decide on an optimal course of action. The strategic approaches for blackjack and poker differ fundamentally, reflecting the core nature of each game. Blackjack, a game of near-perfect information, can be mastered through a combination of mathematically derived optimal strategies and statistical advantage play. Poker, a game of imperfect information and opponent psychology, demands a foundation in probabilistic reasoning and risk management. This section details the algorithmic core for both games, providing a blueprint for rational and, ultimately, profitable decision-making.

### **2.1 Mastering Blackjack: From Optimal Strategy to Advantage Play**

The path to creating a winning blackjack agent is a well-defined, two-step process. The first step is to build a "perfect" player that makes no strategic mistakes, effectively minimizing the casino's inherent house edge. The second step is to overlay a system of advantage play that allows the agent to identify and capitalize on situations where the statistical advantage shifts in its favor.

#### **Foundation: Basic Strategy**

For any combination of a player's hand and a dealer's visible up-card, there exists one mathematically optimal decision (Hit, Stand, Double Down, or Split) that maximizes the player's expected return over the long run. This set of optimal decisions is known as "Basic Strategy." The agent's first requirement is a flawless implementation of this strategy. This is most commonly achieved by encoding the complete Basic Strategy chart into a data structure like a dictionary or a multi-dimensional array, which serves as a quick lookup table.8 The game logic itself involves creating data structures to represent a deck of cards (typically a list of tuples like ('K', 'Spades')), assigning values to each card (e.g., using a dictionary where 'K' maps to 10 and 'A' maps to 11), and managing the game flow of dealing, hitting, and standing.9 A Python-based simulator can be built to verify the correctness of the Basic Strategy implementation by running millions of hands and ensuring the loss rate converges to the theoretical minimum for the specific ruleset in use.10

#### **Gaining the Edge: Card Counting**

Basic Strategy alone cannot overcome the house edge. To achieve a positive expectation, the agent must engage in card counting. This technique works by tracking the ratio of high-value cards to low-value cards remaining in the deck (or shoe). A deck rich in high cards (Aces and 10s) is favorable to the player, while a deck rich in low cards benefits the dealer.11

The most common and effective system for beginners and experts alike is the **Hi-Lo system**.12 Its implementation requires two key metrics:

1. **Running Count:** The agent maintains a single integer value, the "running count," which starts at 0 after a shuffle. As each card is dealt, the agent updates the count: it adds \+1 for low cards (2, 3, 4, 5, 6), subtracts \-1 for high cards (10, J, Q, K, A), and does nothing for neutral cards (7, 8, 9).12 This count is a running tally of the cards that have been removed from play.  
2. **True Count:** In games with multiple decks, the running count is not a sufficient measure of player advantage. A running count of \+5 is far more significant when only one deck remains than when five decks remain. Therefore, the agent must normalize the running count by dividing it by the number of decks estimated to be left in the shoe. This calculation yields the "true count," a more accurate measure of the player's advantage.13 The agent's perception system must be able to estimate the number of remaining decks, often by visually assessing the size of the discard tray or the remaining stack in the shoe.

#### **Monetizing the Edge: Bet Spreading**

A positive true count is strategically useless unless the agent adjusts its wager size accordingly. This is the single most critical component of profitable card counting and the primary source of a counter's advantage.15 The strategy is known as **bet spreading**.

The principle is simple: the agent must vary its bet size in direct proportion to its perceived advantage. When the true count is negative or neutral, indicating the dealer has the advantage, the agent should wager the absolute minimum amount allowed at the table. As the true count becomes positive and increases, indicating a growing player advantage, the agent must aggressively increase its bet size.11

The magnitude of this spread is crucial. Analysis shows that approximately 80% of a card counter's profit comes from this strategic betting, not from deviating from Basic Strategy.15 To gain even a marginal long-term advantage (less than 1%), a professional-level card counter needs to employ a bet spread with a ratio of at least 1-to-12 units. For example, if the table minimum is $25 (one unit), the agent must be prepared to bet up to $300 when the count is sufficiently high. To achieve a more substantial win rate, a spread of 1-to-16 ($25 to $400) or greater is often required.15

The agent's betting logic can be implemented as a function of the true count. A simple but effective rule is to wager (true\_count \- 1\) betting units when the true count is \+2 or higher, and one unit otherwise.13 For instance, at a $10 table, if the true count is \+5, the agent would bet (5 \- 1\) \* $10 \= $40. More sophisticated, non-linear bet spreads can be calculated using specialized software like CVCX to optimize the trade-off between expected value and risk of ruin for a given bankroll size.16

### **2.2 The Rational Poker Player: A Foundation in Mathematical Decision-Making**

Unlike blackjack, poker is a game of incomplete information with no single, universally optimal "basic strategy." Every decision is context-dependent, revolving around probabilities, risk assessment, and opponent tendencies. The foundation of a strong poker AI is not a lookup table, but a deep, functional understanding of the core mathematical principles that govern profitable play.

#### **Core Concepts of Poker Mathematics**

1. **Pot Odds:** This is the most fundamental concept in poker decision-making. Pot odds represent the ratio of the current size of the pot to the cost of a contemplated call.17 This ratio determines the minimum *equity* (the probability of winning the hand at showdown) required to make a call a break-even or profitable play.  
   * **Calculation:** Pot Odds \= (Current Pot Size \+ Bet Size) : (Bet Size)  
   * **Example:** The pot is $80. An opponent bets $20. The total pot is now $100 ($80 \+ $20). The agent must call $20 to potentially win $100. The pot odds are $100-to-$20, or 5-to-1.  
   * **Conversion to Equity:** To be useful, this ratio must be converted to a percentage. The required equity is (Cost of Call) / (Total Pot Size after Call). In the example, this is $20 / ($80 \+ $20 \+ $20) \= $20 / $120 ≈ 16.7%. The agent must believe its hand has more than a 16.7% chance of winning to justify the call based on pot odds alone.18  
2. **Expected Value (EV):** The ultimate arbiter of any poker decision is Expected Value. EV represents the average amount of money a player can expect to win or lose by making a particular decision if the same situation were repeated infinitely.20 The agent's objective in every situation is to choose the action (bet, call, raise, fold) that has the highest EV. A positive EV (+EV) play is profitable in the long run, while a negative EV (-EV) play is a losing one. The EV of folding is always zero.21  
   * **Formula for Calling:** EV\_call \= (Equity \* Pot\_Size\_After\_Opponent\_Bets) \- ((1 \- Equity) \* Call\_Size)  
   * Example: Using the previous scenario, the agent needs to call $20 to win a pot of $100. The agent estimates its equity to be 25% (e.g., holding a flush draw).  
     EV\_call \= (0.25 \* $100) \- (0.75 \* $20) \= $25 \- $15 \= \+$10.  
     This is a \+EV call. On average, every time the agent makes this call, it will profit $10.  
3. **Implied Odds:** Pot odds and direct EV calculations are limited because they only consider the money currently in the pot. Implied odds extend this calculation by factoring in the potential money that can be won on *future* betting rounds (the turn and river) if the agent successfully completes a drawing hand.22 This concept is crucial, as it can justify calls that are \-EV based on direct pot odds alone.  
   * Calculation: It is impossible to calculate implied odds with perfect precision, as it requires predicting future actions.24 However, one can calculate the minimum additional amount (X) that must be won on later streets to make a current call break-even. A simplified formula derived from the EV equation is:  
     X \= (Amount\_to\_Call / Required\_Equity) \- Total\_Pot\_Size\_after\_Call  
   * Example: The pot is $100, and an opponent bets $50. The total pot is $150, and the call is $50. The agent has a draw with 20% equity. The pot odds are 3-to-1 ($150-to-$50), requiring 25% equity. Based on direct odds, this is a fold. How much more must be won on the river to justify this call?  
     Total\_Pot\_Size\_after\_Call \= $100 \+ $50 \+ $50 \= $200.  
     The required equity is 25%, but the agent only has 20%. The agent needs to make up for this deficit.  
     The minimum break-even pot size would be one where the $50 call represents 20% of the total pot. Break-even Pot \= $50 / 0.20 \= $250.  
     Since the pot will only be $200 after the call, the agent must expect to win an additional X \= $250 \- $200 \= $50 on the river if it hits its draw.23 The agent must then make a qualitative judgment: given the opponent's tendencies and the board texture, is it realistic to expect to extract at least another $50? If so, the call becomes \+EV.

A central theme of the user's query was how the amount wagered affects the odds. The analysis of these two games reveals a fundamental dichotomy in game theory. In blackjack, the player's wager is a consequence of the odds. The composition of the remaining deck dictates a specific player advantage (the true count), and the optimal bet size is a direct, one-way function of that advantage. A large bet does not make a favorable card more likely to appear; rather, the high probability of a favorable card makes a large bet the correct action. The causal relationship is linear and unidirectional: Game State (True Count) → Optimal Bet.

In poker, this relationship is a dynamic feedback loop. The player's wager actively *shapes* the odds of the game progressing. A bet is not merely a claim on the pot; it is a tool that manipulates the opponent's decision-making process. By betting a certain amount, the agent sets the pot odds for the opponent.17 A large bet gives the opponent poor odds, potentially forcing them to fold a hand that had a reasonable chance to win. This action, generating "fold equity," changes the range of possible hands the opponent might hold. Consequently, the agent's own equity against this new, filtered range of hands is altered. A small bet, conversely, offers attractive odds, inducing calls from a wider, weaker range of hands. The wager is an active probe, a signal, and a filter that constantly redefines the probabilistic landscape of the game. The causal relationship is cyclical: Agent's Belief about Opponent's Hand → Agent's Bet → Opponent's Reaction (New Observation) → Agent's Updated Belief. This distinction is paramount: the blackjack agent is a statistician capitalizing on a known state, while the poker agent is a strategist actively influencing an uncertain one.

## **Section 3: Advanced Game State Modeling with Markov Processes**

To move beyond simple algorithmic play and build truly sophisticated AI agents, it is necessary to formally model the underlying structure of these games. Markovian frameworks provide the mathematical language for describing systems that evolve through a sequence of states with probabilistic transitions. They are essential for deriving optimal policies for decision-making under uncertainty. This section will introduce the core concepts of Markov chains and demonstrate how they lead to two distinct modeling approaches—the Markov Decision Process (MDP) for blackjack and the more complex Partially Observable Markov Decision Process (POMDP) for poker—revealing the profound theoretical differences between these two games.

### **3.1 The Stochastic Nature of Card Games: An Introduction to Markov Chains**

At its core, a card game is a stochastic process. The sequence of cards dealt from a shuffled deck is a sequence of random events. This process can be modeled as a **Markov chain**, a mathematical model that describes transitions between states in a state space. The defining characteristic of this model is the **Markov property**: the probability of transitioning to any future state depends only on the current state, not on the sequence of states that preceded it.

In the context of a card game, the "state" is the precise composition of the unseen cards remaining in the deck or shoe. When a card is dealt, the system transitions to a new state (a deck with one fewer card). The probability of the next card being, for example, an Ace, is determined entirely by the number of Aces and the total number of cards currently in the deck, not by the order in which the previous cards were dealt. This framework provides the formal mathematical basis for all probability calculations, such as determining the odds of completing a flush in poker or the dealer busting in blackjack.

### **3.2 Solving Blackjack: A Markov Decision Process (MDP) Approach**

Because the state of a blackjack game (player's cards, dealer's up-card, and the composition of the remaining deck) is fully observable to the player, it can be modeled as a **Markov Decision Process (MDP)**. An MDP extends a Markov chain by introducing an agent that can take actions, influencing the state transitions and receiving rewards.25

#### **Formalization of Blackjack as an MDP**

An MDP is formally defined by a tuple (S, A, T, R, γ):

* **States (S):** A state s ∈ S must capture all information necessary to make an optimal decision. For blackjack, a sufficient state representation is a tuple: (player\_total, dealer\_up\_card, has\_usable\_ace). A more complex state representation for a card-counting agent would also include the composition of the remaining deck.27  
* **Actions (A):** The set of actions a ∈ A(s) available to the agent in a given state. For example, from a state representing a hand of (11, 7, false), the available actions might be {Hit, Stand, Double Down}.  
* **Transition Function (T(s, a, s')):** This function, P(s' | s, a), gives the probability of transitioning from state s to a new state s' after taking action a. For example, if the action is Hit, the transition probabilities are determined by the likelihood of drawing each card value from the remaining deck. In a simplified "infinite deck" model, these probabilities are constant (e.g., 4/13 for a 10-value card).25  
* **Reward Function (R(s, a, s')):** This function defines the reward received after a transition. In blackjack, rewards are typically sparse. The reward is 0 for all intermediate actions (like hitting), with a terminal reward being issued at the end of the hand: \+1 for winning, \-1 for losing, 0 for a push, and \+1.5 for a natural blackjack.27  
* **Discount Factor (γ):** A value between 0 and 1 that discounts future rewards. For a single hand of blackjack, it is typically set to 1, as the goal is to maximize the immediate outcome of the hand.

#### **Solving the MDP for an Optimal Policy**

The goal of solving an MDP is to find an optimal policy, π\*(s), which specifies the best action to take in any given state to maximize the expected cumulative reward. This policy is precisely the Basic Strategy chart. Two primary algorithms are used to find this policy:

1. Value Iteration: This is a dynamic programming algorithm that iteratively computes the optimal value function, V\*(s), for each state. The value of a state is the expected reward an agent can achieve starting from that state and following the optimal policy. Value Iteration is based on the Bellman equation 28:

   $$V\_{k+1}(s) \\leftarrow \\max\_{a \\in A(s)} \\sum\_{s'} T(s, a, s')$$

   The algorithm initializes all state values to 0 and repeatedly applies this update for all states. The values V\_k(s) are guaranteed to converge to the optimal values V\*(s). Once the optimal value function is found, the optimal policy is easily extracted by choosing the action that maximizes the expected value in each state.26  
2. Q-Learning: Q-learning is a model-free reinforcement learning algorithm that can find the optimal policy without requiring an explicit model of the transition function T and reward function R. It works by learning an action-value function, Q(s, a), which represents the value of taking action a in state s. The update rule is 29:

   $$Q(s, a) \\leftarrow Q(s, a) \+ \\alpha$$

   Here, α is the learning rate. By repeatedly playing the game (or simulating it) and applying this update, the Q values converge to the optimal Q\* values, from which the optimal policy can be derived. This approach is particularly useful if the exact deck composition rules are unknown or too complex to model directly.29

### **3.3 Navigating Uncertainty in Poker: The Partially Observable MDP (POMDP) Framework**

The MDP framework collapses when applied to poker. The fundamental reason is that the full state of the game is not observable. The agent does not know the opponent's private hole cards, which is the most critical piece of information in the game.30 This is the defining characteristic of an **imperfect information game**, and it requires a more powerful framework: the **Partially Observable Markov Decision Process (POMDP)**.

#### **Formalization of Poker as a POMDP**

A POMDP extends the MDP framework by explicitly modeling the agent's uncertainty about the true state of the world.

* **Belief State (b):** This is the central concept of a POMDP. Instead of knowing the single true state s, the agent maintains a **belief state**, b, which is a probability distribution over the entire state space S. In poker, the belief state is a probability distribution over all possible two-card hands the opponent could hold.30 Initially, this distribution might be uniform over all hands the opponent has not folded.  
* **Observations (Ω):** The agent does not see the state directly. Instead, it receives an **observation** o ∈ Ω that provides a clue about the underlying state. In poker, the opponent's actions (check, bet, raise) are the observations. A large bet, for example, is an observation that makes strong hands more likely in the opponent's distribution, while a check makes weaker hands more likely.  
* **Belief Update:** After taking an action a and receiving an observation o, the agent uses Bayes' rule to update its belief state from b to a new belief b'. This process incorporates the new information to refine the agent's understanding of the hidden state. For example, after an opponent raises, the agent updates its belief by increasing the probabilities of strong hands and decreasing the probabilities of weak hands in its distribution for that opponent.

#### **Solving Poker POMDPs**

Solving POMDPs is computationally much harder than solving MDPs because the policy is a function of the belief state, and the belief space is continuous and high-dimensional.

* **Exact Solutions:** For highly simplified versions of poker, such as an 8-card, two-player variant, the number of reachable belief states can be proven to be finite. In such cases, the continuous belief-space POMDP can be transformed into an equivalent but very large discrete-state MDP, where each reachable belief is a state. This resulting MDP can then be solved exactly using dynamic programming methods like value iteration.30  
* **Approximation Methods:** For any real-world variant of poker like Texas Hold'em, the state and belief spaces are astronomically large, making exact solutions impossible. The field of AI has therefore focused on approximation methods. The dominant approaches for tackling these large-scale POMDPs are rooted in game theory and reinforcement learning. Techniques like **Counterfactual Regret Minimization (CFR)** and its many variants, along with advanced **Monte Carlo search** and **deep reinforcement learning** algorithms, are the state-of-the-art for finding near-optimal strategies in these complex, imperfect information environments.31

The choice between an MDP and a POMDP is not a minor technicality; it represents the fundamental theoretical fault line between games of complete and incomplete information. This distinction dictates the entire architecture and complexity of the required AI agent. The reason a world-class blackjack AI can be built on a relatively straightforward MDP solver, while a world-class poker AI requires massive computational power and highly sophisticated approximation algorithms, can be traced back to this single difference. The causal chain of complexity is direct: the hidden information inherent in poker's design necessitates a belief state, which forces the problem into the POMDP framework. The resulting intractability of the belief space makes exact solutions impossible, which in turn necessitates the development of advanced approximation algorithms like CFR and deep RL. The game's initial ruleset determines the entire cascade of required AI technology.

### **Table 2: Comparison of AI Modeling Frameworks for Poker and Blackjack**

| Framework | Game Information Type | Core Concept | State Representation | Key Challenge | Primary Solution Method |
| :---- | :---- | :---- | :---- | :---- | :---- |
| **Markov Decision Process (MDP)** | Perfect (or near-perfect) Information | Value of a known state | A single, fully observable state tuple, e.g., (player\_total, dealer\_up\_card). | Finding the optimal action for every possible state (computational, but tractable). | Dynamic Programming (Value Iteration), Reinforcement Learning (Q-Learning). |
| **Partially Observable MDP (POMDP)** | Imperfect Information | Belief over hidden states | A probability distribution over all possible hidden states, e.g., \`P(opponent\_hand | action\_history)\`. | Managing and acting upon an infinite, continuous belief space. |

## **Section 4: State-of-the-Art AI Architectures for Opponent Modeling and Exploitation**

While the frameworks discussed in the previous section provide the mathematical foundation for optimal play, achieving superior performance in a game like poker requires more than just a grasp of probabilities. Poker is a game played against adaptive opponents, each with their own unique strategies, tendencies, and flaws. The most powerful AI agents are those that can not only play a theoretically sound game but also model their specific opponents' behavior and dynamically adapt their own strategy to exploit weaknesses. This section explores the cutting edge of AI architectures designed for this purpose, tracing the evolution from sequential pattern recognition models to the new paradigm of large-scale transformer-based agents.

### **4.1 Learning from History: Sequential Opponent Modeling with LSTMs**

An opponent's strategy is not a static set of rules but a dynamic process that unfolds over a sequence of actions. A player's decision to bet on the river is influenced by their actions on the turn, flop, and pre-flop. To capture these temporal dependencies, Recurrent Neural Networks (RNNs), and specifically Long Short-Term Memory (LSTM) networks, are a natural fit. LSTMs are designed to learn patterns in sequential data, making them well-suited for modeling the action history of a poker player.33

#### **Architecture and Implementation**

A highly effective architecture for an adaptive LSTM-based poker agent was developed to explicitly separate short-term and long-term memory.34 This model consists of two parallel LSTM modules that feed into a final decision network:

1. **Game Module:** This module is composed of multiple LSTM blocks and is responsible for processing the sequence of moves made by both players *within a single hand*. Its internal state is reset at the beginning of each new hand. This allows it to capture tactical, in-game patterns, such as recognizing a check-raise line of play.  
2. **Opponent Module:** This module consists of a single, larger LSTM block. Its purpose is to model the opponent's overall style and tendencies *across the entire session*. Its internal state is maintained across multiple hands and is only reset when the agent faces a new opponent. This enables it to learn strategic, long-term patterns, such as an opponent's tendency to bluff too frequently or fold too often to aggression.

The input to both modules at each time step is a feature vector representing the current public game state. This vector includes critical information such as the current betting round (pre-flop, flop, turn, river) represented as a one-hot encoding, the agent's estimated winning probability, the amount of chips committed by each player in the current round, and the pot odds being offered.34

The outputs from both the Game Module and the Opponent Module are concatenated and fed into a standard fully-connected neural network. This decision network then outputs a single value that is used to determine the agent's final action (e.g., fold, call, or bet/raise a certain amount). This dual-module architecture allows the agent's decision to be informed by both the immediate tactical situation of the current hand and the broader strategic profile it has learned about the opponent over many hands. This represents a significant advancement over older opponent modeling techniques, which relied on simple "action frequency" counts in predefined contexts and could not capture the nuanced, sequential nature of poker strategy.35

### **4.2 The New Paradigm: Transformer Models and LLMs as Poker Strategists**

The most recent and powerful evolution in AI involves a conceptual shift in how a poker game is represented. Instead of viewing a hand as a sequence of numerical feature vectors, it can be treated as a textual narrative or a sequence of discrete tokens.37 This reframing allows for the application of Transformer architectures, the technology underpinning Large Language Models (LLMs) like GPT, which have demonstrated unparalleled capabilities in understanding context and relationships within sequential data.

#### **Representing Game State and Making Decisions**

In this paradigm, the entire history of a hand is encoded into a single string of text. For example: "Player1 posts SB 0.5bb. Player2 posts BB 1bb. Player3 folds. Player1 calls 0.5bb. Player2 checks. \-- FLOP \-- 7h Kd 2s. Player1 checks. Player2 bets 1.5bb...".37 This textual representation is then fed into a Transformer model.

The core innovation of the Transformer is the **self-attention mechanism**.38 Unlike an LSTM, which processes information chronologically, the self-attention mechanism allows the model to weigh the importance of every previous token in the sequence when predicting the next token (the agent's action). This means a pre-flop action from the beginning of the hand can directly influence a river decision without its signal being diluted through many intermediate time steps. This ability to capture long-range, non-local dependencies is theoretically ideal for poker, where the entire betting history informs the current belief state.

#### **Implementation and Training**

Recent research projects have successfully demonstrated this approach:

* **Fine-Tuning Pre-trained Models:** Projects like **MistralBluff** and **PokerGPT** leverage the power of large, pre-trained LLMs.39 They take a base model (e.g., Mistral 7B) and fine-tune it on a massive dataset of millions of real-world poker hand histories. The data preparation phase is critical, involving cleaning the raw data and formatting it into a standardized prompt-completion format that the LLM can understand.39  
* **Training with Reinforcement Learning:** Fine-tuning on static datasets teaches the model to mimic human play. To surpass this and discover novel, more powerful strategies, reinforcement learning is used. The PokerGPT project employs techniques similar to Reinforcement Learning from Human Feedback (RLHF), where the model's strategies are refined based on the outcomes (winning or losing chips) of its decisions during gameplay.40 This allows the model to learn through experience in a dynamic environment.

### **4.3 Adaptive Play through Deep Reinforcement Learning**

Deep Reinforcement Learning (DRL) offers a powerful framework for training agents through direct interaction and experience, often via self-play. Instead of being explicitly programmed or trained on a fixed dataset, a DRL agent learns by taking actions, observing outcomes, and receiving rewards (or penalties), gradually converging on a policy that maximizes its long-term winnings.

#### **Advanced DRL for Imperfect Information Games**

While standard DRL algorithms like Deep Q-Networks (DQN) can be adapted for opponent modeling, as seen in the DRON architecture 41, imperfect information games like poker present unique challenges that have led to the development of specialized, game theory-aware algorithms.

* **Deep FTRL-ORW:** This is a state-of-the-art, model-free DRL algorithm specifically designed for solving large-scale Imperfect Information Extensive-Form Games (IIEFGs) like poker.42 A major problem with earlier attempts to combine neural networks with the leading poker-solving algorithm, CFR, was the issue of "accumulated approximation error." Errors made by the neural network in early training iterations would propagate and corrupt the learning process in later iterations. Deep FTRL-ORW uses a novel mathematical formulation (Opponent Related Dilated Distance Generating Functions) that ensures the learning update at each step is independent of past approximation errors. This leads to more stable training and provably better convergence to a near-optimal Nash Equilibrium strategy.42  
* **In-Context Exploiter (ICE):** This recent method leverages the power of transformer models for in-context learning.43 The ICE algorithm trains a single, large transformer model on a vast and diverse dataset of opponent strategies. This dataset is generated using both random strategies and strategies collected from the learning processes of other equilibrium-finding algorithms like CFR. The trained ICE model can then play against a completely new, unseen opponent. By observing the opponent's actions in the current game (the "in-context" history), it can infer their strategy and adapt its own play to maximally exploit them, all without needing to update its network weights.43

The historical progression of AI architectures for poker reveals a clear trend towards more sophisticated and holistic models of memory and context. Early methods using action frequencies treated memory as a collection of static, disconnected counters.36 The introduction of LSTMs represented a major leap, modeling memory as an evolving, sequential hidden state that captured the chronological flow of the game.34 The current state-of-the-art, embodied by Transformers, treats memory as the entire, fully accessible history of play. The self-attention mechanism creates a dynamic, weighted graph of relationships between all past events, allowing the model to understand that an opponent's pre-flop action might be the single most important piece of context for a decision on the river. This evolution from static counters to sequential states to relational graphs demonstrates that progress in game-playing AI is intrinsically linked to developing more powerful representations of context and memory.

## **Section 5: Synthesis and Architectural Recommendations**

The preceding sections have dissected the multifaceted challenge of creating a vision-based AI for poker and blackjack, covering the spectrum from low-level perception to high-level strategic modeling. This final section synthesizes these findings into a cohesive architectural blueprint, directly addresses the user's most nuanced query regarding the nature of wagering, and provides concrete recommendations for the implementation and future development of such an agent.

### **5.1 Blueprint for an Integrated AI Agent**

A robust and effective game-playing agent should be designed with a modular architecture, separating distinct functional responsibilities. This approach enhances maintainability, testing, and the ability to upgrade individual components as new technologies emerge. The recommended architecture consists of four primary modules:

1. **Module 1: Perception Engine:** This is the agent's sensory input. Its sole responsibility is to capture the screen and translate the visual information into a structured data format, such as a JSON object. This module should employ a hybrid pipeline for maximum robustness:  
   * **Primary Detector:** A fine-tuned **YOLOv8** model for real-time detection of cards and chips.  
   * **Text Extractor:** The **EasyOCR** library for parsing all textual information on the screen, including bet sizes, pot totals, and player names.  
   * **Verification/Fallback:** An implementation of the **GroundingDINO \+ CNN classifier** pipeline to validate critical detections (e.g., community cards on the flop) or to serve as a fallback if YOLO's confidence is low.  
2. **Module 2: State Tracker:** This module acts as the agent's short-term and long-term memory. It receives the JSON object from the Perception Engine at each step and maintains the canonical game state. Its responsibilities include:  
   * Tracking the sequence of actions within the current hand.  
   * Maintaining player stack sizes and pot totals.  
   * For blackjack, keeping a running and true count based on all observed cards.  
   * For poker, storing the complete action history for the current session against each opponent.  
3. **Module 3: Strategy Core (Game-Specific):** This is the brain of the agent, responsible for decision-making. This module must be game-specific due to the fundamental differences between blackjack and poker.  
   * **For Blackjack:** This core is primarily rule-based and deterministic. It implements a perfect Basic Strategy lookup table, the Hi-Lo counting system to update the true count from the State Tracker, and an aggressive bet spreading function that determines the wager for the next hand based on the final true count of the previous one.  
   * **For Poker:** This core is the learning-based engine. The recommended implementation is a **fine-tuned Transformer model**, following the approach of PokerGPT.40 It takes the formatted game history from the State Tracker as input. Internally, this model implicitly maintains a belief state over the opponent's likely holdings and outputs the action (fold, check/call, or bet/raise size) predicted to have the highest expected value.  
4. **Module 4: Action Executor:** This is the simplest module, acting as the agent's hands. It receives a decision command from the Strategy Core (e.g., "bet $50," "click Hit button") and translates it into the necessary low-level operating system commands (e.g., mouse movements, clicks, keyboard inputs) to interact with the game client's interface.

### **5.2 The Reflexive Nature of Wagering: How Bet Size Shapes the Game**

A central question posed by the user concerned the relationship between the wager amount and the odds of the game. The analysis reveals that this relationship is fundamentally different in the two games, highlighting their core strategic structures.

#### **Blackjack: One-Way Causality**

In blackjack, the relationship between odds and wagering is a one-way street. The odds, as quantified by the true count, are an objective property of the remaining deck composition. This state dictates the optimal bet size. The causal chain is:

Favorable Deck Composition (State) → High True Count (Odds) → Large Optimal Bet

The player's bet is a *passive reaction* to a known statistical advantage. Wagering a large amount does not influence the probability of the next card being a 10\. The bet is simply the mechanism for capitalizing on that pre-existing high probability. The bet size has no reflexive effect on the game's underlying probabilities.

#### **Poker: A Dynamic Feedback Loop**

In poker, the relationship is a continuous, reflexive feedback loop. A player's wager is not a reaction to a known state but an *active intervention* in a game of unknown states. The bet is a tool used to manipulate the game's probabilistic landscape and the opponent's decision-making process. The causal loop is:

Agent's Belief State → Agent's Bet → Opponent's Reaction (Observation) → Agent's Updated Belief State

The bet size shapes the game in several critical ways:

* **Bet as a Filter:** The wager sets the pot odds for the opponent. A large bet presents unfavorable odds, filtering the opponent's continuing range to include mostly strong hands. A small bet presents favorable odds, allowing a wider, weaker range of hands to continue. The bet actively sculpts the probability distribution of the opponent's holdings.  
* **Bet as a Signal:** The bet size sends a signal (which may be true or false—a bluff) about the agent's own hand strength. This signal is an observation that the opponent uses to update *their* belief state about the *agent's* hand.  
* **Bet as an Information Probe:** A small, exploratory bet can be used to cheaply acquire information. The opponent's reaction (folding, calling, or raising) provides a valuable new observation that allows the agent to significantly refine its belief state.

In essence, the blackjack agent bets big because it knows the odds are good. The poker agent bets big to *make* the odds good—either by forcing better hands to fold or by building a large pot when it believes it has the superior hand range. This dynamic interplay is the essence of poker strategy and the reason it must be modeled as a POMDP.

### **5.3 Final Recommendations and Future Directions**

#### **Model Selection and Resources**

* **For Blackjack:** The optimal approach is a deterministic one. A meticulously implemented **Basic Strategy engine, combined with a robust Hi-Lo card counting system and an aggressive, bankroll-optimized bet spread**, is sufficient to create a winning player. This agent is computationally lightweight and can be run effectively on a standard CPU.  
* **For Poker:** To achieve state-of-the-art performance, the recommended path is to leverage the power of large-scale, learning-based models. The most promising approach involves **fine-tuning a Transformer-based LLM on a massive corpus of hand histories, followed by further refinement through deep reinforcement learning via self-play**. This is a computationally intensive endeavor, requiring significant GPU resources for both training and, depending on the model size, inference.

#### **Future Directions**

The field of game-playing AI is moving beyond creating highly specialized, single-game experts. The new frontier is the development of more general, transferable reasoning abilities. Recent work, such as the SPIRAL framework, has shown that an LLM trained via self-play on simple games like Kuhn Poker can learn fundamental reasoning concepts like expected value calculation and case-by-case analysis. These learned skills then transfer to improve performance on completely unrelated domains, such as mathematical reasoning and general problem-solving.44

This suggests that the future of game AI is not merely about solving games. It is about using the well-defined, objective-rich environments of games as a crucible to forge more general and powerful artificial intelligence. The agent described in this report represents the current state-of-the-art, but it also serves as a stepping stone toward a future where the strategic reasoning learned at the poker table can be applied to solve complex problems in the real world.

#### **Works cited**

1. Stephy-Cheung/Yolov4\_project-Object\_detection\_pokercards: Training Yolov4 model on custom dataset poker cards reading in a Black Jack game and provide game suggestion. \- GitHub, accessed October 16, 2025, [https://github.com/Stephy-Cheung/Yolov4\_project-Object\_detection\_pokercards](https://github.com/Stephy-Cheung/Yolov4_project-Object_detection_pokercards)  
2. PD-Mera/Playing-Cards-Detection: Just an simple project to ... \- GitHub, accessed October 16, 2025, [https://github.com/PD-Mera/Playing-Cards-Detection](https://github.com/PD-Mera/Playing-Cards-Detection)  
3. Gholamrezadar/yolo11-poker-hand-detection-and-analysis \- GitHub, accessed October 16, 2025, [https://github.com/Gholamrezadar/yolo11-poker-hand-detection-and-analysis/](https://github.com/Gholamrezadar/yolo11-poker-hand-detection-and-analysis/)  
4. Poker Game State Detection | CS231n \- Stanford University, accessed October 16, 2025, [https://cs231n.stanford.edu/2024/papers/poker-game-state-detection.pdf](https://cs231n.stanford.edu/2024/papers/poker-game-state-detection.pdf)  
5. Easyocr vs Tesseract (OCR Features Comparison) \- Iron Software, accessed October 16, 2025, [https://ironsoftware.com/csharp/ocr/blog/ocr-tools/easyocr-vs-tesseract/](https://ironsoftware.com/csharp/ocr/blog/ocr-tools/easyocr-vs-tesseract/)  
6. OCR comparison: Tesseract versus EasyOCR vs PaddleOCR vs MMOCR \- Toon Beerten, accessed October 16, 2025, [https://toon-beerten.medium.com/ocr-comparison-tesseract-versus-easyocr-vs-paddleocr-vs-mmocr-a362d9c79e66](https://toon-beerten.medium.com/ocr-comparison-tesseract-versus-easyocr-vs-paddleocr-vs-mmocr-a362d9c79e66)  
7. \[D\] TesseractOCR vs PaddleOCR vs EasyOCR for Japanese text extraction \- Reddit, accessed October 16, 2025, [https://www.reddit.com/r/MachineLearning/comments/170j47f/d\_tesseractocr\_vs\_paddleocr\_vs\_easyocr\_for/](https://www.reddit.com/r/MachineLearning/comments/170j47f/d_tesseractocr_vs_paddleocr_vs_easyocr_for/)  
8. Blackjack with Basic Strategy. \- GitHub, accessed October 16, 2025, [https://github.com/v/blackjack](https://github.com/v/blackjack)  
9. Blackjack Python: Beginner Tutorial \- Teach Your Kids Code, accessed October 16, 2025, [https://teachyourkidscode.com/blackjack-python-beginner-tutorial/](https://teachyourkidscode.com/blackjack-python-beginner-tutorial/)  
10. AttackingOrDefending/Blackjack-Strategy-Simulator ... \- GitHub, accessed October 16, 2025, [https://github.com/AttackingOrDefending/Blackjack-Strategy-Simulator](https://github.com/AttackingOrDefending/Blackjack-Strategy-Simulator)  
11. Card counting \- Wikipedia, accessed October 16, 2025, [https://en.wikipedia.org/wiki/Card\_counting](https://en.wikipedia.org/wiki/Card_counting)  
12. Card Counting \- Brendan Sudol, accessed October 16, 2025, [https://brendansudol.github.io/card-counting-game/](https://brendansudol.github.io/card-counting-game/)  
13. 3 Ways to Count Cards in Blackjack \- wikiHow, accessed October 16, 2025, [https://www.wikihow.com/Count-Cards-in-Blackjack](https://www.wikihow.com/Count-Cards-in-Blackjack)  
14. PrintName/BlackjackCardCounter: Python based blackjack ... \- GitHub, accessed October 16, 2025, [https://github.com/PrintName/BlackjackCardCounter](https://github.com/PrintName/BlackjackCardCounter)  
15. Understanding Blackjack Bet Spread Requirements for a Card Counter in Blackjack, accessed October 16, 2025, [https://www.blackjackreview.com/wp/2017/08/02/understanding-blackjack-bet-spread-requirements/](https://www.blackjackreview.com/wp/2017/08/02/understanding-blackjack-bet-spread-requirements/)  
16. A Card Counter's Guide to Betting at Blackjack \- Blackjack ..., accessed October 16, 2025, [https://www.blackjackapprenticeship.com/card-counters-guide-betting-blackjack/](https://www.blackjackapprenticeship.com/card-counters-guide-betting-blackjack/)  
17. Pot odds \- Wikipedia, accessed October 16, 2025, [https://en.wikipedia.org/wiki/Pot\_odds](https://en.wikipedia.org/wiki/Pot_odds)  
18. Pot Odds in Poker: A Complete Guide, accessed October 16, 2025, [https://worldpokerfederation.org/poker/how-to-play-poker/strategy/pot-odds-in-poker-complete-guide/](https://worldpokerfederation.org/poker/how-to-play-poker/strategy/pot-odds-in-poker-complete-guide/)  
19. Pot Odds In Poker – Master The Numbers \- Cardplayer Lifestyle, accessed October 16, 2025, [https://cardplayerlifestyle.com/pot-odds-poker/](https://cardplayerlifestyle.com/pot-odds-poker/)  
20. Poker Math: Calculate Pot Odds and Expected Value on the Fly | GGPoker, accessed October 16, 2025, [https://ggpoker.com/blog/poker-math-calculate-pot-odds-and-expected-value-on-the-fly/](https://ggpoker.com/blog/poker-math-calculate-pot-odds-and-expected-value-on-the-fly/)  
21. Learn Poker: What Are Pot Odds? How to Calculate Pot Odds and ..., accessed October 16, 2025, [https://www.masterclass.com/articles/learn-poker-what-are-pot-odds](https://www.masterclass.com/articles/learn-poker-what-are-pot-odds)  
22. How to Calculate Implied Odds in Your Games | Blog \- POKERCODE, accessed October 16, 2025, [https://www.pokercode.com/blog/implied-odds](https://www.pokercode.com/blog/implied-odds)  
23. How to Use Implied Odds Like a Veteran Pro \- Upswing Poker, accessed October 16, 2025, [https://upswingpoker.com/implied-odds-poker-strategy/](https://upswingpoker.com/implied-odds-poker-strategy/)  
24. How to Calculate Implied Odds in Your Poker Games \- PokerCoaching.com, accessed October 16, 2025, [https://pokercoaching.com/blog/implied-odds/](https://pokercoaching.com/blog/implied-odds/)  
25. PLAY BLACKJACK THE MARKOVIAN WAY \- WDSI, accessed October 16, 2025, [http://wdsinet.org/Annual\_Meetings/2000\_Proceedings/pdffiles/papers/281.pdf](http://wdsinet.org/Annual_Meetings/2000_Proceedings/pdffiles/papers/281.pdf)  
26. Peeking Blackjack, accessed October 16, 2025, [https://web.stanford.edu/class/archive/cs/cs221/cs221.1196/assignments/blackjack/index.html](https://web.stanford.edu/class/archive/cs/cs221/cs221.1196/assignments/blackjack/index.html)  
27. How to Lose Blackjack (Optimally) – Connie Trojan, accessed October 16, 2025, [https://www.lancaster.ac.uk/stor-i-student-sites/connie-trojan/2022/05/05/how-to-lose-blackjack-optimally/](https://www.lancaster.ac.uk/stor-i-student-sites/connie-trojan/2022/05/05/how-to-lose-blackjack-optimally/)  
28. Discussion 4 Solutions, accessed October 16, 2025, [https://mlserver1.cs.siue.edu/ai\_24fa/wrksht/u3/section4-v2\_solutions.pdf](https://mlserver1.cs.siue.edu/ai_24fa/wrksht/u3/section4-v2_solutions.pdf)  
29. An MDP Blackjack Agent \- SIGCHI Conference Paper Format, accessed October 16, 2025, [https://www.cs.uml.edu/ecg/uploads/AIfall12/reilly\_blackjack\_mdp.pdf](https://www.cs.uml.edu/ecg/uploads/AIfall12/reilly_blackjack_mdp.pdf)  
30. Best-response play in partially observable card ... \- Frans A. Oliehoek, accessed October 16, 2025, [https://www.fransoliehoek.net/docs/Oliehoek05Benelearn.pdf](https://www.fransoliehoek.net/docs/Oliehoek05Benelearn.pdf)  
31. Solving Imperfect Information Poker Games Using Monte Carlo ..., accessed October 16, 2025, [https://www.researchgate.net/publication/347433090\_Solving\_Imperfect\_Information\_Poker\_Games\_Using\_Monte\_Carlo\_Search\_and\_POMDP\_Models](https://www.researchgate.net/publication/347433090_Solving_Imperfect_Information_Poker_Games_Using_Monte_Carlo_Search_and_POMDP_Models)  
32. Best-response Play in Partially Observable Card Games \- Frans Oliehoek, accessed October 16, 2025, [https://www.fransoliehoek.net/publications/htmlfiles/b2hd-Oliehoek05Benelearn.html](https://www.fransoliehoek.net/publications/htmlfiles/b2hd-Oliehoek05Benelearn.html)  
33. Predicting Human Decision Making with LSTM \- Bytes of Minds Lab, accessed October 16, 2025, [https://www.bytesofminds.com/pdfs/papers/lin2022predicting.pdf](https://www.bytesofminds.com/pdfs/papers/lin2022predicting.pdf)  
34. Evolving Adaptive LSTM Poker Players for Effective Opponent ..., accessed October 16, 2025, [https://nn.cs.utexas.edu/downloads/papers/xun.aaai17.pdf](https://nn.cs.utexas.edu/downloads/papers/xun.aaai17.pdf)  
35. Opponent Modeling in Texas Hold'em \- Utrecht University Student Theses Repository Home, accessed October 16, 2025, [https://studenttheses.uu.nl/bitstream/handle/20.500.12932/8062/OpponentModelinginTexasHoldem.pdf?sequence=1\&isAllowed=y](https://studenttheses.uu.nl/bitstream/handle/20.500.12932/8062/OpponentModelinginTexasHoldem.pdf?sequence=1&isAllowed=y)  
36. Improved Opponent Modeling in Poker, accessed October 16, 2025, [https://poker.cs.ualberta.ca/publications/ICAI00.pdf](https://poker.cs.ualberta.ca/publications/ICAI00.pdf)  
37. \[D\] Transformers for poker bot : r/MachineLearning \- Reddit, accessed October 16, 2025, [https://www.reddit.com/r/MachineLearning/comments/10zix8k/d\_transformers\_for\_poker\_bot/](https://www.reddit.com/r/MachineLearning/comments/10zix8k/d_transformers_for_poker_bot/)  
38. LLM Transformer Model Visually Explained \- Polo Club of Data Science, accessed October 16, 2025, [https://poloclub.github.io/transformer-explainer/](https://poloclub.github.io/transformer-explainer/)  
39. JulienDelavande/MistralBluff: A poker bot using mistral llm ... \- GitHub, accessed October 16, 2025, [https://github.com/JulienDelavande/MistralBluff](https://github.com/JulienDelavande/MistralBluff)  
40. \[2401.06781\] PokerGPT: An End-to-End Lightweight Solver for Multi-Player Texas Hold'em via Large Language Model \- arXiv, accessed October 16, 2025, [https://arxiv.org/abs/2401.06781](https://arxiv.org/abs/2401.06781)  
41. Opponent Modeling in Deep Reinforcement Learning, accessed October 16, 2025, [http://proceedings.mlr.press/v48/he16.pdf](http://proceedings.mlr.press/v48/he16.pdf)  
42. An Efficient Deep Reinforcement Learning Algorithm for Solving ..., accessed October 16, 2025, [https://ojs.aaai.org/index.php/AAAI/article/view/25722/25494](https://ojs.aaai.org/index.php/AAAI/article/view/25722/25494)  
43. In-Context Exploiter for Extensive-Form Games \- arXiv, accessed October 16, 2025, [https://arxiv.org/html/2408.05575v1](https://arxiv.org/html/2408.05575v1)  
44. \[2506.24119\] SPIRAL: Self-Play on Zero-Sum Games Incentivizes Reasoning via Multi-Agent Multi-Turn Reinforcement Learning \- arXiv, accessed October 16, 2025, [https://arxiv.org/abs/2506.24119](https://arxiv.org/abs/2506.24119)