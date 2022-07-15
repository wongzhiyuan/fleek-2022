class LocalSettings {
  bool emailVerified = false;
  bool verificationSent = false;
  bool messageNotifsOn = true;
  String providerID;
  String hotline;
  String email;

  void reset() {
    this.emailVerified = false;
    this.verificationSent = false;
    this.messageNotifsOn = true;
    providerID = null;
    hotline = null;
    email = null;
  }
}