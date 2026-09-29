/// Automation IDs (handheld spec decision 6) — the single source for both
/// `TestId` wrappers in widgets and `byTestId` / `bySemanticsIdentifier`
/// finders in tests. Format: `<screen>.<element>` in lowerCamel. Android
/// exposes these as `resource-id`, iOS as `accessibilityIdentifier`.
///
/// Add new IDs here in the screen's group; never inline string literals.
abstract class NavIds {
  static const home = 'nav.home';
  static const sale = 'nav.sale';
  static const enquiry = 'nav.enquiry';
  static const menu = 'nav.menu';
}

abstract class MenuIds {
  static const sheet = 'menu.sheet';
  static const settings = 'menu.settings';
  static const logout = 'menu.logout';
}

abstract class LoginIds {
  static const userCodeField = 'login.userCodeField';
  static const passwordField = 'login.passwordField';
  static const passwordVisibility = 'login.passwordVisibility';
  static const signInButton = 'login.signInButton';
  static const qrLoginButton = 'login.qrLoginButton';
  static const settingsButton = 'login.settingsButton';
  static const errorMessage = 'login.errorMessage';
}

abstract class HomeIds {
  static const greeting = 'home.greeting';
  static const sessionLine = 'home.sessionLine';
  static const onlineStatus = 'home.onlineStatus';
  static const billsStat = 'home.billsStat';
  static const netSalesStat = 'home.netSalesStat';
  static const scanField = 'home.scanField';
  static const tileRegister = 'home.tile.register';
  static const tileSale = 'home.tile.sale';
  static const tileCheckout = 'home.tile.checkout';
  static const tileEnquiry = 'home.tile.enquiry';
  static const suspendedBills = 'home.suspendedBills';
  static const customerResult = 'home.customerResult';
}

abstract class SettingsIds {
  static const saveButton = 'settings.saveButton';
  static const cancelButton = 'settings.cancelButton';
  static const terminalSection = 'settings.terminalSection';
  static const saleModeSection = 'settings.saleModeSection';
  static const sellOnline = 'settings.saleMode.online';
  static const sellOffline = 'settings.saleMode.offline';
  static const endpointsSection = 'settings.endpointsSection';
  static const deviceSection = 'settings.deviceSection';
}
