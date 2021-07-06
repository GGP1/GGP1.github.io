---
title: "Cryptoeconomics"
date: 2021-07-06
draft: false
cover:
    image: "/images/cryptoeconomics.jpg"
    alt: "Cryptoeconomics"
    caption: ""
    relative: false
    hidden: false
---

The stability of modern monetary systems depends on people's trust on the governments and institutions that rule them.

Central banks impose the currencies used and arbitrarily control money supply and interest rates. Their negligent manipulation have caused inflation and hiperinflation crises all over the world, making people to look for better ways of exchanging assets to protect their property.

The search for a solution along with the advances in computer science and cryptography led to the creation of decentralized virtual systems that do not require to trust on a third party to exchange assets in a secure, transparent and reliable way. These systems are part of what it's called **cryptoeconomics**.

# History

With World War II coming to and end in 1944, 44 alied nations celebrated the [Bretton Woods](https://en.wikipedia.org/wiki/Bretton_Woods_system) agreement that established the rules, institutions and procedures that would regulate the international monetary system after the war.

The countries agreed on fixing their currencies to the U.S. dollar, and to tie the U.S. dollar to gold at a price of $35 per ounce. The currencies were now (supposedly) indirectly backed by and exchangeable for gold.

![Bretton Woods Conference](/images/bretton_woods_conference.jpg "Bretton Woods Conference")

A few years later, a series of conflicts known as the [Cold War](https://www.history.com/topics/cold-war/cold-war-history) started between the United States, the Soviet Union and their respective allies. To face them, the United States began spending high amounts of money and in 1950 its balance of payments swung negative. 

What's worse, in 1964-1965 its president Lyndon Johnson launched the [Great Society Program](https://www.history.com/topics/1960s/great-society), a set of domestic programs to eliminate poverty, reduce crime, abolish inequality and improve the environment, which represented even more deficit. 

As a consequence of all these spending, other countries became concern that the U.S. didn't have enough gold reserves to back the money that was being printed and started exchanging their dollars for gold and demanding physical delivery.

> Before, the exchanges of currencies for gold were done within the banks of the U.S. to avoid the logistics of shipping the gold.

To prevent the outflow of gold, the American President Richard Nixon suspended *"temporarily"* the convertibility of the U.S. dollar to gold or other reserve assets in August 15, 1971. In March 1973 the fixed exchange rate system became a floating exchange rate system, giving birth to **fiat currencies**.

Fiat currencies are, by definition, backed by **nothing other than government promises and people's faith on them**. They are measured only against each other and can be easily manipulated by the governments.

> [Fiat](https://www.merriam-webster.com/dictionary/fiat) (decree) means "authoritative or arbitrary order".

![Fiat currencies](/images/fiat_currencies.jpg)

With the objective of offering an alternative to the traditional financial system, several entities tried implementing their own private currencies that were tied not to trust but to reserves of precious metals, like most nations used to do prior to the Bretton Woods agreement:

- **E-gold**: a digital currency backed with gold coins and operated by Gold & Silver Reserve Inc. (U.S.) that allowed users to transfer value from one account to another instantly inside their website.
- **Liberty Reserve**: similarly to e-gold, it was a digital currency that let users transfer money through a website with low transaction fees. Deposited funds where converted to Liberty Reserve Dollars that were tied to the U.S. dollar or to ounces of gold.
- **Liberty dollar**: a private currency that was issued in minted metal rounds (similar to coins), gold and silver certificates and electronic currency (eLD). Liberty Dollars were backed by gold, silver, platinum, or copper.

All three services were shut down by the United States government, charging their owners with federal crimes for money counterfeiting, laundering and conspiracy. 

> The U.S. government also [prohibited](https://www.law.cornell.edu/uscode/text/18/486) the use of silver bullion, or any other metal coin or bar not issued under government authority, from being used as currency in commerce.

These projects provided a refuge against fiat currencies' inflation and a simple and fast way of transferring value, however, their users were **still required to trust a central authority** and their reserves and services management. 

Many researchers and computer scientists became aware that removing trust from the equation could only be achieved by a **decentralized and distributed system**.

In 1998, **Wei Dai** [revealed](http://www.weidai.com/bmoney.txt) **B-Money**, a distributed electronic cash system described by his author as *"a scheme for a group of untraceable digital pseudonyms to pay each other with money and to enforce contracts amongst themselves without outside help"*. 

Wei's proposal emphasizes in **users' participation** to maintain a separate database containing all participants' accounts balances, solve computational problems to create money, and validate, conclude and enforce contracts.

> The idea of digital cash was originally introduced in a research paper called *["Blind signatures for untraceable payments"](https://www.chaum.com/publications/Chaum-blind-signatures.PDF)* wrote by **David Chaum** in 1983. However, David's goal wasn't a monetary reform but to give the individuals control over their own information.

This same year, **[Bit Gold](https://nakamotoinstitute.org/bit-gold/)** showed up. It was proposed by **Nick Szabo** in an attempt to provide a solution to money counterfeiting, theft and its value depending on a trusted central authority. 

The idea behind Bit Gold was an online automated currency with **minimal dependence on trusted third parties** and that could be securely stored, transferred, and assayed with similar minimal trust.

In 2005, Nick wrote a [post](https://unenumerated.blogspot.com/2005/12/bit-gold.html) were he mentioned interesting notions like **proof of work securely timestamped**, **distributed property title registry** and a **chain of string bits**. 

Altough B-Money and Bit Gold were never implemented, many of their concepts were later used in the creation of the first and currently most popular digital currency.

On February, 2009 an individual/group under the name of **Satoshi Nakamoto**, whose identity is still unknown, [posted](https://p2pfoundation.ning.com/forum/topics/bitcoin-open-source) that he has developed a new open source P2P (peer-to-peer[^1]) e-cash system called **[Bitcoin](https://bitcoin.org/bitcoin.pdf)**.

![Bitcoin](/images/bitcoin.jpg)

Bitcoin replaces trust based models with a **decentralized electronic payment system based on cryptographic proof**. 

Since its introduction it has inspired many others in the creation of such systems for exchanging both information and property titles by using digital coins, commonly known as **cryptocurrencies**. 

There are currently more than 7,000 of them available on the market, each one with different philosophies, goals and structures.

# Cryptocurrencies

A cryptocurrency is a **digital asset whose integrity is protected by cryptography**[^2]. It is in most cases decentralized, divisible and fungible. 

In other words, it's essentially **bits of information that represent value inside a virtual system, which is designed to provide a secure, transparent and reliable infrastructure for their exchange**. 

Cryptocurrencies offer a **public way for two parties to exchange property titles with minimum/none trust on the other**. 

They are easy to store and transport, and enable the possibility to transfer assets with no economic, geographical nor political limitations and without relying on states, banks or other central institutions for it.

The technology that powers most cryptocurrencies' systems and provides a way of achieving such challenges is known as *blockchain*.

## Blockchain

A blockchain is a [**distributed ledger**](https://en.wikipedia.org/wiki/Distributed_ledger) (append-only database) managed by a decentralized network that stores transactions grouped in blocks, each block is linked to the previous one in the chain. A block contains:

- a *hash*[^3] of the current block's content
- the hash of the previous block
- a [nonce](https://en.wikipedia.org/wiki/Cryptographic_nonce) (number used only once)
- a timestamp
- other information (bits, weight, size, merkle root, number of transactions, difficulty, etc.). 

![Blockchain blocks content](/images/blockchain_blocks.png "Blockchain blocks content")

These blocks are considered *immutable* as it's **infeasible to modify them** once they are appended to the database. The deeper the block is in the chain the harder it is to change.

This immutability provides great **transparency** to the system, absolutely all the blocks and their information can be seen by anyone, anytime. Take a look at the first block of the Bitcoin blockchain [here](https://www.blockchain.com/btc/block/0).

> Transactions within a block are organized using a [merkle tree](https://en.wikipedia.org/wiki/Merkle_tree), which helps verify their integrity.

Each node in the network has a database containing all the blockchain information and a need to coordinate all the nodes' data arises, this is one of the problems that *distributed systems* face and why many *consensus mechanisms* were created.

### Distributed systems and consensus mechanisms

A **distributed system** is a group of computers (also referred as nodes) operating independently and communicating between each other to exchange and agree on information to perform a task. 

![Consensus mechanisms](/images/consensus_mechanisms.png)

A blockchain network is one of them, it requires to be **reliable, consistent and fault-tolerant** but also needs a way of ensuring that the nodes spend **scarce resources** (electricity, time, etc.) in order to be elegible and participate in the system, otherwise any of them could attempt to inject malicious blocks without much endeavor.

There are multiple mechanisms to achieve this, the two most used in blockchain technologies are *proof of work*[^4] and *proof of stake*.

### Proof of work

In a proof of work (PoW) system, blocks are added to the blockchain by **miners**, which are nodes that compete against each other to **compute a hash** that is lower than the **target**[^5]. This calculation is **computationally expensive**.

To produce the hash, a miner takes the current block content, the previous block's hash and a nonce (number used only once). 

What miners try to brute-force is the **nonce**, they do the calculation over and over again changing its value to get different hashes and hopefully one that is correct. 

> The target difficulty is adjusted by reducing its value (hence reducing the probability of getting a valid hash) to keep block creation at a certain rate (1 per 10 minutes in the case of Bitcoin).

Once a miner finds (or thinks it has) the solution, it broadcasts the hash to the other nodes for them to verify if it is correct, this is done fast as the verification demands a single calculation. 

In case the solution is valid, the miner is **rewarded** with a pre-established amount of coins that may or may not vary over time depending on how the system is configured.

![Proof of work](/images/pow.jpg "Proof of work")

In a blockchain using proof of work, its security relies on the **difficulty of accumulating CPU power**. 

The network always trusts and replicates the **longest** valid chain, hence, corrupting it is only possible by **mining faster than the rest of the network** (having more than 50% of the network's CPU power), this is, producing the longest branch of blocks and making the nodes discard the "honest" one. 

This attack can change the current/future transactions but won't affect previously stored ones. Modifying a past transaction is even harder:

![Proof of work attack](/images/proof_of_work.png)

#### Computational scalability

As the probability of guessing a right hash is **directly proportional** to the hashes per second the miner is able to perform, there is a race going on to make those hashes as fast as possible, which translates in high levels of electricity consumption.

This is one of the main criticisms to proof of work systems, considered by some as *"extremely inefficient"*. However, it's clear that such an effort needs to be made to keep the blockchain secure and thus, **protect the users' property**. 

Cryptocurrencies using a proof of work system **trade computational scalability for social scalability**[^6].

![Cryptocurrency mine](/images/crypto_mine.jpg "Thousands of computers calculating hashes in a cryptocurrency mine")

Environmental impact being addressed as the main downside by some engineers have led them to seek more sustainable solutions. The most used PoW alternative is a CPU power-independent scheme called **proof of stake**.

### Proof of stake

Proof of stake implements a mechanism where the security is accomplished by **validator nodes** that must meet some requirements to perform that role, such as:

- Have a determined quantity of coins, forcing attackers to acquire a large amount of them to perform an attack.
- The product of the number of coins with the amount of time that a single user has held them (the token time is reseted everytime the user transfers it).

> The probability of a node being chosen to validate the next block is proportional to its stake.

![Proof of stake](/images/pos.jpg "Proof of stake")

Furthermore, there are systems that promote what's called **delegated proof of stake** where stake-holder and validators roles are separated, letting the first group to delegate the actual validation role. 

Nevertheless, as the number of block validators is reduced, **it sacrifices decentralization for throughput**, which compromises the blockchain security.

> Delegated proof of stake is better suitable for applications that can trade security for performance. 

## Blockchain use cases

Apart from providing the infrastructure necessary for the exchange of cryptocurrencies, blockchains are also used to execute other applications inside them, here are some explained.

### Smart contracts

Smart contracts are esentially computer programs run and replicated inside a blockchain whose logic is used to formalize deals mathematically. This is, **remove trust from a third party at the time of an agreement**. 

The term was first introduced by *Nick Szabo* to refer to "a set of promises, specified in digital form, including protocols within which the parties perform on these promises". 

![Smart contracts](/images/smart_contracts.png)

A smart contract has the following features:

- **Transparent**: the code is public and accesible by anyone.
- **Hardly-mutable**: nearly impossible to modify after submitted into the blockchain. This is why it's crucial to audit it beforehand and make sure it is programmed as expected.
- **Secure**: it's protected by cryptography.

They provide great functionalities to the blockchain, users can interact with them by executing transactions that run a function defined on the smart contract. 

However, these functionalities come at a cost, it's really difficult (if not impossible) to write **non-hackable and bug-free code**, even if a vulnerability is found it's hard to modify the contract.

In spite of this, there're certainly some interesting use cases if carefully implemented, and this is why *DApps* were created.

### Decentralized applications (DApps)

DApps are a series of **linked smart contracts** that provide an interface for the users to interact with it. 

They can provide high levels of **security, data integrity and transparency** within an application but using them for other purposes may not be the best choice. 

A DApp will never match the performance of a centralized application, it has to execute much more tasks to deliver the features mentioned above. 

What's more, they are hard to mantain (the code is hard to modify) and they may be built to store data or run logic in external centralized servers, eliminating blockchain's advantages.

> Blockchains are not designed to be performant like a distributed system used by Visa or Paypal and matching their transaction per second rate is a logical limitation.

### Non-fungible tokens (NFTs)

NFTs are digital assets inside a blockchain designed to **prove and verify the authenticy and ownership** of an item, which might be tangible or intangible. 

They contain authentication information to help protect the item's owner rights, prevent frauds and yet again remove the trust on other parties to validate the **singularity and originality** of an item. 

> The owner or creator can also store additional metadata inside them (their signature, for example).

Even though anyone could see/download/replicate the item, **NFTs cannot be replicated nor exchanged at equivalency**.

For instance, the below artwork associated NFT was sold for 42,329 Ether (worth US$69.3 million back then) at a british auction house earlier this year.

![Everydays: the first 5000 days by Mike Winkelmann](/images/everydays_the_first_5000_days.jpg "Everydays: the first 5000 days by Mike Winkelmann")

## Crypto finance

Now that we know what a blockchain is and what it can be used for, let's get an insight on cryptocurrencies' prices and how users store and exchange them.

### Wallets

The users, in order to interact with the blockchain and make transactions, need a **wallet**. A wallet is an application that acts as an interface for the users to send and receive coins inside the blockchain. Each wallet has a **public and private key** which are used to **sign and verify** transactions.

The public key is used to identify a wallet, it could be thought as a unique address/username. 

The private key is required to verify the ownership of the coins that are under the wallet with its public key pair. Losing it means losing access to all the coins.

> **Important**: when you buy cryptocurrencies in a centralized exchange they are stored in a wallet owned by that exchange, it's not safe to keep the coins there as they are the main target of cybercriminals, plus you don't really own them. When you withdraw your funds is when they are sent to your wallet (the one locked by your private key and under your control).

Wallets are tipically divided by their internet connectivity into two categories:

- **Hot wallets**: they are connected to the internet and suitable for daily transactions but not for long-term holding as they are more prone to attacks.
- **Cold wallets**: they are stored offline and offer higher security, ideally for holding.

> The two most used types of wallets are hardware and software (desktop, mobile, web) but their differences won't be covered in this post, I invite you to investigate yourself.

### Transactions

Transactions are token transfers between two users **within the blockchain** and each one of them has a **fee** that is rewarded to the miner for calculating the hash of the block. 

The fee policy varies depending on the cryptocurrency but tipically the amount is **not specified** and depends on the supply of the network, it's in charge of the users to choose how much they want to spend (most exchanges offer a default value based on the market average). 

Transactions offering a high reward will be prioritized and those who offer a low amount are in risk of not being even considered by the miners, this means that transferring 1 coin costs the same as transferring 1.000.000 of them.

> One of the main concerns of past implementations of electronic payments was **double-spending**, which is solved in modern implementations by recording and agreeing a single public history of the transactions in the order they were received, considering the earliest as the valid one.

### Price

The price of a cryptocurrency, like any economic asset, fluctuates based on **supply and demand**. The demand is generally led by the project that the cryptocurrency operates on and the team that is developing it. 

> Unlike fiat currencies they are not created out of thin air but require the miners to spend **scarce resources** like time and electricity for it. I will be writing an article about money, if Bitcoin can be considered money and comparing it with fiat and commodity currencies.

In some cases **the supply is fixed** to a certain amount to be reached at some point in time, making them predictable and scarce by definition, as well as eliminating monetary inflation after the date set. This is why the term **digital gold** is often used. 

In spite of this comparison, note that the amount of available gold is, even though barely increasing, still unknown and more could be found on earth or space.

> Note that many of the coins fall out of circulation due to the owners losing access to their private key and thus to the wallets, reducing the supply even more.

To put an example, Bitcoin is set to issue a total of **21 millon BTC** to be reached in **2140**. Its current supply rate is of 6.25 BTC per 10 minutes (block mining rate), this amount is reduced by 50% every four years.

![Bitcoin inflation vs time](/images/bitcoin_time_vs_inflation.png)

### Volatility

Cryptocurrencies are well-known for being super volatile, that is, their price fluctuation is high. One of the core reasons for this is that it's an **emerging** and **immature** market.

The introduction of a new technology that attempts to replace well-established institutions generates a lot of uncertainity and speculation, which derives in the variation of the consumers' appreciation about the value of the cryptocurrencies.

> In certain cases the lack of liquidity of assets within the market also increases volatility (specially in the beggining), making it easier for big stakers to "move the needle".

Some people have found volatility an issue and this has incentivized the creation of so called *"stable coins"*.

### Stable coins

Stable coins are cryptocurrencies **backed by a company or fundation reserve**, with specific funding processes. They are designed to be **1-to-1 pegged to another asset**, tipically the U.S. dollar. 

Despite being called "stable", these coins are **only as stable as the assets they are tied to**, for instance, having a coin pegged to the Argentine Peso provides almost no benefits.

This type of coins provide a secure, fast and easy method to transfer value, nevertheless, **users must trust the reserves management of the insitutions behind them** and, in case they're tied to a fiat currency, trust the central authority issuing it. 

In addition, some stable coins add the ability for the backers to stop transactions if they consider them illicit, which completely destroys one of cryptocurrencies' core principles, *decentralization*.

## Fundamental principles

### Decentralization

Cryptocurrencies have opened up the possibility of exchanging assets in a secure and reliable way with no central authority being capable of controlling the transactions nor the system in which they are executed.

This is, decentralization **eliminates the single point of failure of a system** as there's no authority whose decisions could impact its functionality.

At the same time, it makes the system virtually impossible to stop or shut down. Each node has a copy of the database and as long as they can communicate between each other it will keep working.

However, it's not an intrinsic characteristic of cryptocurrencies, in fact, centralized ones controlled by a state, bank, company or institution exist.

### Anonymity

Blockchains are designed to be pseudonymous - they use hashes to identify users instead of personal information -, but when users interact with them anonymity becomes really tricky.

Centralized exchanges and applications that offer an interface to operate with the blockchain or companies that accept cryptos as a form of payment **must verify the identity of their users**, otherwise they wouldn't be able to recognise who is sending/receiving currencies. 

Depending on their location they could also be under Know-your-customer (KYC) and anti-money-laundering (AML) regulations, being required to provide sensitive information to the authorities in order to operate.

> Decentralized exchanges, however, tend to be more private as they only operate with information inside the blockchain and under less regulations as they are not in control of the funds.

Futhermore, every single transaction remains in the immutable ledger **forever**, if your account's public key is associated with your identity, **absolutely all** the transactions you have made in the past are now exposed, as well as the public key addresses of the parties that interacted with you - whose identities can be linked as well.

To prevent the linking, some privacy-focused projects make extensive use of cryptography to hide transaction addresses, wallet balances and other private information. 

### Transparency

Instead of trusting a central authority, **cryptocurrencies put trust in code** (cryptographic proofs), which in most cases is **public and free to copy and modify**.

The systems behind cryptocurrencies are developed and maintained by a group of developers that have permissions to commit to the project. 

> It's important to note that the decisions taken by the developers concerning the future of the system **could potentially impact** the price of the coin.

In many cases, potential changes in the codebase are **deeply discussed and reviewed** by the community members before implemented, however, this might not be done in all of the projects. 

> When two groups differ radically in the scope of the project a [hard fork](https://www.investopedia.com/terms/h/hard-fork.asp) can be produced, where one group stays with the current state and the other copies and modifies it to meet their needs. In these cases, the new version gives each of the nodes the same amount of coins that had in the old version.

![Bitcoin Core source code](/images/bitcoin_source_code.jpg "Bitcoin Core source code")

Investing in a cryptocurrency operated by a **non open-source** technology is something I do **not** recommend, no matter who is developing it. 

Open-source means the code is open to the public and that **anyone** can read the codebase of the project and **verify** that what is being promoted is actually how it works. 

On the other hand, private codebases could hide malicious functionalities like, for example, let their developers issue coins discretionary or manipulate transactions and their information. 

# Conclusion

Cryptography, economics and computer science have been combined for the creation of digital systems that aim to improve the way in which multiple parties interact. 

Agreements that previously required to trust an intermediary to supervise them now can be executed in a predictable and transparent way by an algorithm with no owner. 

Cryptocurrencies merely represent value and work as a medium of exchange inside those systems.

It's uncertain if these technologies will be the ones used to make daily transactions in the future, but they are clearly a big step towards the decentralization and digitalization of human's communications.

[^1]: Peer-to-peer refers to an operation done by members of the same network without relying on a dedicated central server.
[^2]: Cryptography is a process that ensures the confidentiality and integrity of some data by converting it in an unintelligible form. Its goal is the data to be readable and processable by only those for whom it is intended.
[^3]: A hash is a mathematical one-way function that converts an input of arbitrary length into an encrypted output of a fixed length. Using this function on the same data will return the same result, allowing users to verify the information integrity. One-way means it cannot be reverse-engineered, given an output we cannot discover the input.
[^4]: The proof of work mechanism was introduced by **Adam Black** in 1997 and originally used in hashcash to limit email spam and denial-of-service attacks.
[^5]: The target hash is the maximum allowed value that a successful hash can be, it is determined by the difficulty.
[^6]: Nick Szabo's definition: Social scalability is the ability of an institution – a relationship or shared endeavor, in which multiple people repeatedly participate, and featuring customs, rules, or other features which constrain or motivate participants' behaviors - to overcome shortcomings in human minds and in the motivating or constraining aspects of said institution that limit who or how many can successfully participate.