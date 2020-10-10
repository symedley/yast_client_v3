# yast_client_v3

***An app (both iOS and Android) that interacts with your yast.com account to display time management data and help fix common mistakes in your data.***

This is a learning exercise for me. I created this project to teach myself Flutter, Dart, Firebase Cloudstore and using HTTP for basic API interaction.

**It is a learning exercise,** which means that it's rough around the edges. Some might say that I'm trying to make Dart look like K&R C. (Well, maybe I am, just a little.) 

## Functional Description
### What is Yast.com
Yast is a time management tool. It's great. Try it out. Their web console works very well. Their Android app, however, leaves something to be desired. It's inefficient, won't work offline and lacks features.
### Yast Client v2
An app that has some of the features that the official yast Android app lacks. My app is not a full featured client. At risk of sounding like a broken record, it is a *demo project* and *learning project*. 

## Getting Started

To build yast_client_v2, you would clone or fork the project, use your IDE to import the flutter project and hook it up to a Firebase project for the database. However, I can't imagine why you would want to because, *it's just a demo app and a learning project.* There's almost certainly nothing here that would be applicable to other projects.

### Prerequisites

This project depends on 
 -   firebase_core: ^0.2.5
 -   cloud_firestore: ^0.8.1
 -   shared_preferences: 0.4.2
 -   xml: ^3.2.3
 -   http: ^0.11.3+17
 - flutter_circular_chart: ^0.1.0
 -   cupertino_icons: ^0.1.2
 
to use Cloud Firestore, see the instructions for setting up a database [Getting Started with Cloud Firestore](https://firebase.google.com/docs/firestore/quickstart). 

### Installing

This assumes that you have flutter installed, which includes a Dart installation, and an IDE such as AndroidStudio with the [flutter plug in](https://plugins.jetbrains.com/plugin/9212-flutter) installed.

Clone the repo 
```
git clone https://github.com/symedley/yast_client_v2.git
```
Launch AndroidStudio, 'open project' and select the root folder of the cloned repo. This project depends on several packages. Get them by typing
```
flutter packages get
```
Follow instructions to [set up Cloud Firestore for flutter.](https://pub.dartlang.org/packages/cloud_firestore)

## Built With

* out of the box Flutter build tools and dependency management for Flutter version  0.8.2 • channel beta 


## Authors

* **[Susannah Medley](https://github.com/symedley)** - *Initial work* 

## License

This project is © 2018 Susannah Medley - see the [LICENSE.md](LICENSE.md) file for details

Please [contact me directly](https://github.com/symedley) if you want to turn any part of this into an open source project.


## Acknowledgments

* Thank you to the folks at yast.com for providing an API and good documentation.
* Thank you to the author of [flutter_circular_chart](https://pub.dartlang.org/packages/flutter_circular_chart)


> Written with [StackEdit](https://stackedit.io/).

