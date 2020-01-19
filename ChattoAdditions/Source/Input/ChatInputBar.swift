/*
 The MIT License (MIT)

 Copyright (c) 2015-present Badoo Trading Limited.

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
*/

import UIKit

public enum ChatInputType: Int {
    case voice, text
}

public protocol ChatInputBarDelegate: class {
    func inputBarShouldBeginTextEditing(_ inputBar: ChatInputBar) -> Bool
    func inputBarDidBeginEditing(_ inputBar: ChatInputBar)
    func inputBarDidEndEditing(_ inputBar: ChatInputBar)
    func inputBarDidChangeText(_ inputBar: ChatInputBar)
    func inputBarSendButtonPressed(_ inputBar: ChatInputBar)
    func inputBar(_ inputBar: ChatInputBar, shouldFocusOnItem item: ChatInputItemProtocol) -> Bool
    func inputBar(_ inputBar: ChatInputBar, didReceiveFocusOnItem item: ChatInputItemProtocol)
    
}

public protocol ChatInputBarTextViewDelegate: class {
    func inputBar(_ inputBar: ChatInputBar, _ textView: UITextView)
    func inputBarDidTyping(_ inputBar: ChatInputBar, _ textView: UITextView) // detecting text is typing from keyboard

}

@objc
open class ChatInputBar: ReusableXibView {

    public weak var delegate: ChatInputBarDelegate?
    public weak var textDelegate: ChatInputBarTextViewDelegate?
    weak var presenter: ChatInputBarPresenter?

    public var shouldEnableSendButton = { (inputBar: ChatInputBar) -> Bool in
        return !inputBar.textView.text.isEmpty
    }

    @IBOutlet public weak var textView: ExpandableTextView!
    @IBOutlet public weak var sendButton: UIButton!
    @IBOutlet public weak var holderView: UIStackView!

    @IBOutlet weak var topBorderHeightConstraint: NSLayoutConstraint!

    @IBOutlet var stackViewWidthConstraint: NSLayoutConstraint!

    let recordingImage = "sendIcon"
    let sendImage = "sendIcon"

    public var chatInputType: ChatInputType = .text // default mode
    public var enableVoiceMode: Bool = false {
        didSet {
           if enableVoiceMode {
                chatInputType = .voice
                self.sendButton.isEnabled = true
                self.sendButton.setBackgroundImage(UIImage(named: recordingImage)!, for: .normal)
            } else {
                chatInputType = .text
                self.sendButton.isEnabled = self.shouldEnableSendButton(self)
                self.sendButton.setBackgroundImage(UIImage(named: sendImage)!, for: .normal)
            }
        }
    }

    class open func loadNib() -> ChatInputBar {
        guard let view = Bundle(for: self).loadNibNamed(self.nibName(), owner: nil, options: nil)!.first as? ChatInputBar
            else { fatalError("ChatInputBar nib is not found")}
        view.translatesAutoresizingMaskIntoConstraints = false
        view.frame = CGRect.zero
        return view
    }

    override class func nibName() -> String {
        return "ChatInputBar"
    }
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        self.topBorderHeightConstraint.constant = 1 / UIScreen.main.scale
        self.textView.scrollsToTop = false
        self.textView.delegate = self
//        self.holderView.scrollsToTop = false
        self.sendButton.isEnabled = false
        self.textView.layer.cornerRadius = 20.0
        self.textView.layer.masksToBounds = true
//        self.sendButton.setBackgroundImage(UIImage(named: sendImage)!, for: .normal)
    }

    open override func updateConstraints() {
        super.updateConstraints()
    }

    open var showsTextView: Bool = true {
        didSet {
            self.setNeedsUpdateConstraints()
            self.setNeedsLayout()
            self.updateIntrinsicContentSizeAnimated()
        }
    }

    open var showsSendButton: Bool = true {
        didSet {
            self.setNeedsUpdateConstraints()
            self.setNeedsLayout()
            self.updateIntrinsicContentSizeAnimated()
        }
    }

    public var maxCharactersCount: UInt? // nil -> unlimited

    private func updateIntrinsicContentSizeAnimated() {
        let options: UIView.AnimationOptions = [.beginFromCurrentState, .allowUserInteraction]
        UIView.animate(withDuration: 0.25, delay: 0, options: options, animations: { () -> Void in
            self.invalidateIntrinsicContentSize()
            self.layoutIfNeeded()
            //self.superview?.layoutIfNeeded()
        }, completion: nil)
    }

    open override func layoutSubviews() {
        self.updateConstraints() // Interface rotation or size class changes will reset constraints as defined in interface builder -> constraintsForVisibleTextView will be activated
        super.layoutSubviews()
    }

    var inputItems = [ChatInputItemProtocol]() {
        didSet {
            let inputItemViews = self.inputItems.map { (item: ChatInputItemProtocol) -> ChatInputItemView in
                let inputItemView = ChatInputItemView()
                inputItemView.inputItem = item
                inputItemView.delegate = self
                return inputItemView
            }
            for view in inputItemViews {
                view.translatesAutoresizingMaskIntoConstraints = false
                self.holderView.addArrangedSubview(view)
            }
//            self.holderView.arrangedSubviews(inputItemViews)
        }
    }

    open func becomeFirstResponderWithInputView(_ inputView: UIView?) {
        self.textView.inputView = inputView

        if self.textView.isFirstResponder {
            self.textView.reloadInputViews()
        } else {
            self.textView.becomeFirstResponder()
        }
    }

    public var inputText: String {
        get {
            return self.textView.text
        }
        set {
            self.textView.text = newValue
            self.updateSendButton()
            self.chatInputType = .text
            self.textDelegate?.inputBar(self, textView)
            self.delegate?.inputBarDidChangeText(self)
            self.textDelegate?.inputBarDidTyping(self, textView)
        }
    }
    
    open func updateSendButton() {
        self.sendButton.layer.removeAllAnimations()
        if chatInputType == .text {
            if !self.enableVoiceMode {
                // voice mode is false
                self.sendButton.isEnabled = shouldEnableSendButton(self)//true
//                self.sendButton.setBackgroundImage(UIImage(named: sendImage)!, for: .normal)
            } else {
                // voice mode is true
                if shouldEnableSendButton(self) { //text typed and voice mode
//                    self.sendButton.setBackgroundImage(UIImage(named: sendImage)!, for: .normal)
                } else { // no text and voice mode
                    chatInputType = .voice
                    self.sendButton.isEnabled = true
//                    self.sendButton.setBackgroundImage(UIImage(named: recordingImage)!, for: .normal)
                }
            }
        } else { // .voice input
            self.sendButton.isEnabled = true
            if shouldEnableSendButton(self) { //text typed and voice mode
//                self.sendButton.setBackgroundImage(UIImage(named: sendImage)!, for: .normal)
            } else { // no text and voice mode
//                self.sendButton.setBackgroundImage(UIImage(named: recordingImage)!, for: .normal)
            }
        }
       
    }

    @IBAction func buttonTapped(_ sender: AnyObject) {
        if chatInputType == .text {
            self.presenter?.onSendButtonPressed()
            self.delegate?.inputBarSendButtonPressed(self)
        }
         textView.originalText = ""
    }

    public func setTextViewPlaceholderAccessibilityIdentifer(_ accessibilityIdentifer: String) {
        self.textView.setTextPlaceholderAccessibilityIdentifier(accessibilityIdentifer)
    }

    open func updateStackViewWidth(_ showCancel: Bool) {
        if showCancel {
            self.stackViewWidthConstraint.constant = 70
        } else {
             self.stackViewWidthConstraint.constant = 40
        }
        UIView.animate(withDuration: 0.3) {
            self.holderView.semanticContentAttribute = .forceLeftToRight
            self.layoutIfNeeded()
        }
    }
}

// MARK: - ChatInputItemViewDelegate
extension ChatInputBar: ChatInputItemViewDelegate {
    func inputItemViewTapped(_ view: ChatInputItemView) {
        self.focusOnInputItem(view.inputItem)
    }

    public func focusOnInputItem(_ inputItem: ChatInputItemProtocol) {
        let shouldFocus = self.delegate?.inputBar(self, shouldFocusOnItem: inputItem) ?? true
        guard shouldFocus else { return }

        self.presenter?.onDidReceiveFocusOnItem(inputItem)
        self.delegate?.inputBar(self, didReceiveFocusOnItem: inputItem)
    }
}

// MARK: - ChatInputBarAppearance
extension ChatInputBar {
    public func setAppearance(_ appearance: ChatInputBarAppearance) {
        self.textView.font = appearance.textInputAppearance.font
        self.textView.textColor = appearance.textInputAppearance.textColor
        self.textView.tintColor = appearance.textInputAppearance.tintColor
        self.textView.textContainerInset = appearance.textInputAppearance.textInsets
        self.textView.setTextPlaceholderFont(appearance.textInputAppearance.placeholderFont)
        self.textView.setTextPlaceholderColor(appearance.textInputAppearance.placeholderColor)
        self.textView.setTextPlaceholder(appearance.textInputAppearance.placeholderText)
        self.textView.layer.borderColor = appearance.textInputAppearance.borderColor.cgColor
        self.textView.layer.borderWidth = appearance.textInputAppearance.borderWidth
//        self.tabBarInterItemSpacing = appearance.tabBarAppearance.interItemSpacing
//        self.tabBarContentInsets = appearance.tabBarAppearance.contentInsets
        self.sendButton.contentEdgeInsets = appearance.sendButtonAppearance.insets
        self.sendButton.setTitle(appearance.sendButtonAppearance.title, for: .normal)
        appearance.sendButtonAppearance.titleColors.forEach { (arg) in
            let (state, color) = arg
            self.sendButton.setTitleColor(color, for: state.controlState)
        }
        self.sendButton.titleLabel?.font = appearance.sendButtonAppearance.font
    }
}

// MARK: UITextViewDelegate
extension ChatInputBar: UITextViewDelegate {
    public func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        return self.delegate?.inputBarShouldBeginTextEditing(self) ?? true
    }

    public func textViewDidEndEditing(_ textView: UITextView) {
        self.presenter?.onDidEndEditing()
        self.delegate?.inputBarDidEndEditing(self)
    }

    public func textViewDidBeginEditing(_ textView: UITextView) {
        updateSendButton()
        self.presenter?.onDidBeginEditing()
        self.delegate?.inputBarDidBeginEditing(self)
    }

    public func textViewDidChange(_ textView: UITextView) {
        
        if let textView = textView as? ExpandableTextView {
            // replacing password char "•" with text length
            textView.text = textView.isSecuredEntryOn ? String(repeating: "•", count: textView.text.count) : textView.text
        }
        self.updateSendButton()
        self.textDelegate?.inputBar(self, textView)
        self.delegate?.inputBarDidChangeText(self)
    }
   
    public func textView(_ textView: UITextView, shouldChangeTextIn nsRange: NSRange, replacementText text: String) -> Bool {

        if self.enableVoiceMode {
            let currentText = textView.text as NSString
            let changedText = currentText.replacingCharacters(in: nsRange, with: text)
            if changedText.isEmpty { // voice input is enabled
                self.chatInputType = .voice // change to voice mode if field is empty
            } else {
                self.chatInputType = .text //text input is enabled
            }
        }
        self.textDelegate?.inputBarDidTyping(self, textView)

        if let textView = textView as? ExpandableTextView, textView.isSecuredEntryOn {
            let currentText = textView.originalText as NSString
            textView.originalText = currentText.replacingCharacters(in: nsRange, with: "")//trim last change
            textView.originalText += text // append change
        }

        let range = self.textView.text.bmaRangeFromNSRange(nsRange)
        if let maxCharactersCount = self.maxCharactersCount {
            let rangeLength = textView.text.replacingCharacters(in: range, with: text).count
            let canType = rangeLength <= maxCharactersCount
            return canType
        }
        
        return true
    }
}

private extension String {
    func bmaRangeFromNSRange(_ nsRange: NSRange) -> Range<String.Index> {
        guard
            let from16 = utf16.index(utf16.startIndex, offsetBy: nsRange.location, limitedBy: utf16.endIndex),
            let to16 = utf16.index(from16, offsetBy: nsRange.length, limitedBy: utf16.endIndex),
            let fromLength = String.Index(from16, within: self),
            let toLength = String.Index(to16, within: self)
            else { return  self.startIndex..<self.startIndex }
        return fromLength ..< toLength
    }
}
