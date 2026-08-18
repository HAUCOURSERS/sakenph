# Commuter Guide Application with Multimodal Transport using A* and Yen's Algorithm

This is a system prototype using a hybrid algorithm used to generate transit routes 
in Angeles and Mabalacat City. It lets users input an origin and destination point
and see what routes they can take from three different modes (jeep, tricycle, walking).

## Features

-   Public transport trips with suggested multimodal routes in Angeles and Mabalacat
-   Automatic fare calculation for jeepneys and tricycles
-   Estimated Time of Arrival based on average mode speed and traffic conditions
-   Display jeepney routes and tricycle terminal locations in the map

> [!NOTE]
> This requires the backend app to function properly. Please follow the instructions
> in the backend repository's instructions to host it.

## Pre-requisites

You may need to install the following to run the app

-   Flutter
-   Android SDK (^24)

## How to connect to backend

1.  Clone the repo using Git or download it.
2.  From the terminal, change directory to the project folder.
3.  Run `flutter pub get` to install dependencies.
3.  Run the app using `flutter run`.

> [!NOTE]
> Although the app is optimized for Android, running using Chrome is technically possible
> but discouraged due to package limitations and UI bugs that may only be present in Web
> instances. Only use this if running Android is not possible. If running the app using
> Web, specify the web port using `8080` in the run command.