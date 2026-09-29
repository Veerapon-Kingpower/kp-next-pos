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

abstract class SaleIds {
  static const header = 'sale.header';
  static const backButton = 'sale.backButton';
  static const scanField = 'sale.scanField';
  static const scanError = 'sale.scanError';
  static const staleNotice = 'sale.staleNotice';
  static const totalLine = 'sale.totalLine';
  static const netPay = 'sale.netPay';
  static const tabBuying = 'sale.tab.buying';
  static const tabBasket = 'sale.tab.basket';
  static const backToBuyingButton = 'sale.backToBuyingButton';
  static const emptyState = 'sale.emptyState';
  static const privilege = 'sale.privilege';
  static const basketNotice = 'sale.basketNotice';
  static const checkoutButton = 'sale.checkoutButton';
  static const customerButton = 'sale.customerButton';
  static const discountButton = 'sale.discountButton';
  static const saveButton = 'sale.saveButton';
  static const moreButton = 'sale.moreButton';
  static const moreSheet = 'sale.moreSheet';
  static const orderTypeShopping = 'sale.orderType.shopping';
  static const orderTypeDelivery = 'sale.orderType.delivery';
  static const orderTypePreOrder = 'sale.orderType.preOrder';
  static const voidConfirm = 'sale.voidConfirm';

  /// One cart line, keyed by its cart `row`.
  static String line(String row) => 'sale.line.$row';
}

abstract class EditLineIds {
  static const page = 'editLine.page';
  static const undoButton = 'editLine.undoButton';
  static const saveButton = 'editLine.saveButton';
  static const saveCloseButton = 'editLine.saveCloseButton';
  static const qtyDecrease = 'editLine.qty.decrease';
  static const qtyIncrease = 'editLine.qty.increase';
  static const qtyValue = 'editLine.qty.value';
  static const amount = 'editLine.amount';
  static const netAmount = 'editLine.netAmount';
  static const serialField = 'editLine.serialField';
  static const freezeSwitch = 'editLine.freezeSwitch';
  static const lockDiscountSwitch = 'editLine.lockDiscountSwitch';
  static const pickupCollect = 'editLine.pickup.collect';
  static const pickupTake = 'editLine.pickup.take';
  static const voidButton = 'editLine.voidButton';
}

abstract class DiscountIds {
  static const sheet = 'discount.sheet';
  static const closeButton = 'discount.closeButton';
  static const modePercent = 'discount.mode.percent';
  static const modeAmount = 'discount.mode.amount';
  static const modePromo = 'discount.mode.promo';
  static const valueField = 'discount.valueField';
  static const netPreview = 'discount.netPreview';
  static const applyButton = 'discount.applyButton';
  static const cancelButton = 'discount.cancelButton';

  static String preset(int percent) => 'discount.preset.$percent';
}
