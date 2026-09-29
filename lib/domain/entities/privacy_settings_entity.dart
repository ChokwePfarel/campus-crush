class PrivacySettingsEntity {
  final bool isProfilePrivate;      // hides profile from discover
  final bool isSpottedVisible;      // opt in ORR out of Spotted feature
  final bool showUniversity;        // toggle university display
  final bool allowMessageRequests;  // strangers can/can't DM

  PrivacySettingsEntity({
    this.isProfilePrivate = false,
    this.isSpottedVisible = true,
    this.showUniversity = true,
    this.allowMessageRequests = true,
  });
}
