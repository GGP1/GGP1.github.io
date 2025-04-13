---
title: "Protect your information"
date: 2022-02-20
draft: false
# categories:
#  - cybersecurity
ShowReadingTime: false
ShowBreadCrumbs: false
ShowPostNavLinks: true
image: "/images/data_protection.jpg" # image path/url
tags:
  - Security
  - Encryption
  - Entropy
  - Randomness
---

Every day we are more connected with our devices, we use them to share information, store capital, buy products, work, learn, for entertainment; basically anything. 

Along with these services come our accounts, that hold and will hold more value than ever as the time goes by. 

There's no doubt we need them safe. In this article, I will try to help you **protect your information**.

## Passwords

Passwords are the **most critical part of every system security**, they are the key that protect very sensitive information so it's specially important to understand how to manage them carefully.

The vast majority of users typically choose simple and easy to remember passwords, or at least that's what they try; people regularly lose access to their accounts because of forgetting them. 

There's no much to worry about if you can't log into an account that does not contain relevant information, but what if it has a meaningful amount of money in it, or if you use the account to work, or even if it's the only way to access some specific data?

These passwords commonly contain names, dates, numbers or a combination of them but this **is not secure** and should be **avoided** at all cost.

To put it clear:

- if you reuse your passwords
- or either you use one unique password per account and can remember all of them

it's highly probable that they are **weak and easily guessable**.

> By the way, using your phone's notes or carrying around a paper with them written down in plaintext is **unsafe** and **risky**.

A password like "masterYODA", "anakin1706" or "-Gandalf$" can be cracked in a matter of **seconds**, the computational power of the graphic cards used for these purposes has increased **tremendously** over the past decade. 

What's more, every year millions of them are [breached](https://en.wikipedia.org/wiki/List_of_data_breaches) throughout the internet; in 2019 a single collection of 21 million passwords was for sale on the web. 

<!-- As if this were not enough, according to Edward Snowden - NSA whistleblower - we should be prepared to protect our passwords against 1 trillion guesses per second! -->

> Many companies take exhaustive security measures to protect the users:
> encryption, bounties, [two-factor authentication](#two-factor-authentication), etc.
> Nevertheless, it's still a really hard task to accomplish, especially because internet was designed on the model of *"a group of mutually trusting users attached to a transparent network"*.

While getting your accounts compromised might seem unlikely to you, it's a daily occurrence all around the world. It's **not** something to get **paranoid** about but is crucial to comprehend how to defend ourselves from cybercriminals.

### Password security

Passwords' *"strength"* is measured using a term called **entropy**. Entropy tells how hard it will be for an attacker to guess a password itself even if he knows the method used in the selection of the password.

It is measured in bits and is calculated by doing `log₂(pool length ^ secret length)`[^1] where the **pool length** is the size of the group from where we take the characters and the **secret length** is how many characters the secret has.

As you may have noticed, what makes a password **exponentially** stronger is its length. Take a look at this table[^2]:

| Password | Pool length | Length | Entropy | Number of possible combinations | Average time taken to crack |
| ----------- | ----------- | ----------- | ----------- | ----------- | ----------- |
| 59e1gbis4x0k | 36 | 12 | 62.04 bits | 4.74 quintillion | 27.42 days |
| 8aun5 hgmy3r | 37 | 12 | 62.51 bits | 6.58 quintillion | 1.27 months |
| cv9ymuoplhk86 | 36 | 13 | 67.21 bits | 170.58 quintillion | 2.74 years |

Incrementing the password's length by 1 is **~26 times** more efficient than adding a character to the pool. This is why you want your passwords to be long rather than just replacing letters with numbers or using a couple of special characters in a short one.

Following this logic, nowadays, it's suggested to use at least 18 characters and a combination of lower cases, upper cases and numbers. A password meeting these requirements looks something like: `lLk9PoOGdfW1y08qNY`. 

If we want to take a step further we can add spaces and special characters: `h>b)E<%RY/ O4|w0LK`, this one it would take 6,385,261,034,886.48 millenniums to crack on average[^3]. 

Another type of secrets are **passphrases**, sequences of words generally longer and easier to remember than passwords. For example: `mayhap shutout pomade marksmen hobbit`.

These passwords and passphrases are secure but, using the **exact same secret** for multiple accounts is a **naive idea**.

![Password reuse](/images/password_reuse.png)

If the details of one of your accounts gets exposed then all the others will be compromised, the attacker would have to find only their emails/usernames, which isn't hard at all. 

So, how can someone remember even one of these long and random passwords? The answer is: there's no reason to do it.

### Password managers

Here's when passwords managers come into play, they let you save your passwords securely by remembering only one, the master password, which is used to **encrypt** all the others and has to be **as strong as possible**. 

> The master password should be long (I'd suggest +20 chars) and not complex enough to forget it, including special characters is a plus but not strictly necessary. Passphrases are probably what you'll find more practical.

This kind of applications let you generate random passwords and protect your credentials (passwords, emails, usernames, files, etc.) against the most specialized attackers by using encryption[^4] and hashing, among other features.

![Keyboard](/images/keyboard0.jpg)

There are many options on the market but I couldn't find any that offers the enjoyable usage of the terminal, sessions and that uses one unique key for encrypting each record, instead of the whole database with the same key. 

That's why I've developed **[Kure](https://www.github.com/GGP1/kure)**, it's free, open source and arguably one of the most secure and private password managers out there. It can also be used in almost any device or platform.

> To give you an idea, it uses the same algorithms ([AES](https://en.wikipedia.org/wiki/Advanced_Encryption_Standard)) the National Security Agency of the United States uses for encrypting **Top Secret** information as well as the [PHC winner](https://github.com/P-H-C/phc-winner-argon2) password hashing function.

However, it's based on the command-line and most people tend not to use it, that's why I suggest you to try one like [KeepassXC](https://keepassxc.org/), it's free, open-source and does a really good job at keeping your data secure as well.

## Two-factor authentication

### Time-based one-time passwords (TOTP)

Two-factor authentication is a form of identification that strengthens an account's security by requiring the user to enter a **code** that can be stored in an authentication app or received via sms/email. 

So apart from something the user knows (*password*), now it is required something it has aswell (*device/service* that provides the code).

> SMS and email are especially susceptible to phishing attacks, prioritize using an application (optimally an open-source one) as it doesn't share the code with anyone.

![TOTP authentication example](/images/2fa.jpg "Time-based one-time passwords")

The code is time-based and it refreshes every 30 seconds, to generate the same code, the client and the server utilize a setup key and the number of seconds that have elapsed since the 00:00:00 UTC on 1 January 1970 (Unix epoch).

TOTPs makes it, not impossible, but much more complicated for an attacker to access an account as it now needs to get its hands on the **constantly refreshing** code.

### Security keys

Security keys provide another way of *two-factor authentication*, they generate codes **locally** with the **hardware** they have integrated, taking advantage of isolation and ensuring the security of the secret generation process. 

> These devices can be used for producing static passwords, digital signatures, OTP, TOTPs and more.

They add another requirement to the authentication of the user which is having access to the physical device.

## Encrypted connections

It's crucial to ensure that the services we use offer **end-to-end encrypted connections**, this means that anyone trying to access the information being sent and received will have to decrypt it, which demands a huge amount of time and computational power.

> Most services' connections are established with **HTTPS** ([HTTP](https://en.wikipedia.org/wiki/Hypertext_Transfer_Protocol) + [TLS](https://en.wikipedia.org/wiki/Transport_Layer_Security)), also known as the green lock before the address box. There are some browser settings and extensions that force HTTPS or warn you if a site does not support it.

![HTTPS](/images/https.png "Verified TLS cerificate")

You should **never** send sensitive information over a **non-encrypted connection**, otherwise, anyone [sniffing](https://www.paessler.com/it-explained/packet-sniffing) the connection is able to read **every single byte of data**.[^5]

## Limited data sharing

The best way to protect your data is, of course, not sharing it. Specially if we consider that companies may exchange information between them, with government agencies and other institutions. 

It's better **not** to enter any private information unless **strictly necessary**, either when the service or other users need to link the account with your identity, otherwise it's preferable to use false profiles.

## Conclusion

Digital information is protected by the knowledge of other information (keys, secrets, codes), we can conclude, then, that **the confidentiality of some information is proportional to the difficulty of guessing or getting access to the secrets that secure it**.

We have covered a few topics concerning computer networks security, there are still more advanced ones, such as cryptography and advanced hacking techniques but they will be referenced in future blogs. 

For now, implementing the security measures that were introduced above will **dramatically decrease** the chances of someone else getting access to your information.

[^1]: `pool length ^ secret length` is the number of possible combinations and `log₂` is used to calculate this information in bits, as each bit has 2 possible states. This helps simplifying large numbers, for example, `log₂(70,000,000) = 26.06 bits`.

[^2]: These values are based on a **brute force attack** and the time taken will **change** as computers become more powerful. 

    A brute force attack consists in trying every possible combination of characters, the average number of attempts that will take an attacker to find the key is **50% percent** of the total, and that's the scenario we are considering. 
    
    There are other techniques like **social engineering**, **dictionary** and **precomputation attacks**, etc. that are more advanced and will require an entire blog to explain them, but you can imagine that if someone wants to get acess to your account, he will have tools to help him.
[^3]: Passwords, passphrases and their security details displayed in this article were provided by a library I created for generating cryptographically secure and higly random secrets called [Atoll](https://www.github.com/GGP1/atoll).
[^4]: Encryption is the process of encoding information with a secret, so only the users knowing the secret can decode it. 

    Encryption is used to ensure **data confidentiality and integrity** while acting as an **authentication** mechanism at the same time. The techniques used for these purposes are generally published, standardized and available to everyone. 
[^5]: VPNs won't be taken into consideration because: 

    1. they don't offer end-to-end encryption (only to/from the VPN server)
    
    2. if we are communicating with one or more users our information will still be vulnerable (their connections aren't encrypted)
    
    3. the user's privacy may be compromised
    
    4. some services block connections received from indentified VPN servers to protect region-specific content
