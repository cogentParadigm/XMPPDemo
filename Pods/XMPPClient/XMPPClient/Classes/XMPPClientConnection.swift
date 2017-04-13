//
//  XMPPClientConnection.swift
//  Pods
//
//  Created by Ali Gangji on 6/18/16.
//
//  This class handles setting up the XMPP connection.
//  1. create instance
//      let connection = XMPPClientConnection()
//  2. set delegate
//      connection.delegate = self
//  3. add modules
//      connection.activate(capabilities)
//      connection.activate(archiving)
//  4. connect
//      connection.connect("user@domain.com", "password")
//
//

import Foundation
import XMPPFramework

@objc public protocol XMPPClientConnectionDelegate {
    @objc optional func xmppConnection(_ sender: XMPPStream!, socketDidConnect socket: GCDAsyncSocket!)
    @objc optional func xmppConnectionDidConnect(_ sender: XMPPStream)
    @objc optional func xmppConnectionDidAuthenticate(_ sender: XMPPStream)
    @objc optional func xmppConnection(_ sender: XMPPStream, didNotAuthenticate error: DDXMLElement)
    @objc optional func xmppConnectionDidDisconnect(_ sender: XMPPStream, withError error: Error)
}

open class XMPPClientConnection: NSObject {
    
    lazy var stream:XMPPStream = {
        let stream = XMPPStream()!
        #if !TARGET_IPHONE_SIMULATOR
            stream.enableBackgroundingOnSocket = true
        #endif
        stream.addDelegate(self, delegateQueue: DispatchQueue.main)
        self.reconnect.activate(stream)
        return stream
    }()
    
    lazy var reconnect:XMPPReconnect = {
        return XMPPReconnect()
    }()
    
    open var delegate:XMPPClientConnectionDelegate?
    var password:String?
    
    open var customCertEvaluation = true
    
    open func connect(username:String, password:String) {
        if (isConnected()) {
            delegate?.xmppConnectionDidConnect?(stream)
        } else {
            stream.myJID = XMPPJID(string:username)
            self.password = password
            try! stream.connect(withTimeout: XMPPStreamTimeoutNone)
        }
    }
    
    open func disconnect() {
        goOffline()
        stream.disconnect()
    }
    
    open func isConnected() -> Bool {
        return stream.isConnected()
    }
    
    open func getStream() -> XMPPStream {
        return stream
    }
    
    open func activate(_ module:XMPPModule) {
        module.activate(stream)
    }
    
    open func send(_ element:DDXMLElement!) {
        stream.send(element)
    }
    
    open func goOnline() {
        let presence = XMPPPresence()
        let domain = stream.myJID.domain
        
        if domain == "gmail.com" || domain == "gtalk.com" || domain == "talk.google.com" {
            let priority: DDXMLElement = DDXMLElement(name: "priority", stringValue: "24")
            presence?.addChild(priority)
        }

        send(presence)
    }
    
    open func goOffline() {
        var _ = XMPPPresence(type: "unavailable")
    }

}

// MARK: XMPPStreamDelegate

extension XMPPClientConnection: XMPPStreamDelegate {
    public func xmppStream(_ sender: XMPPStream!, socketDidConnect socket: GCDAsyncSocket!) {
        delegate?.xmppConnection?(sender, socketDidConnect: socket)
    }
    
    public func xmppStream(_ sender: XMPPStream!, willSecureWithSettings settings: NSMutableDictionary!) {
        let expectedCertName: String? = sender.myJID.domain
        
        if expectedCertName != nil {
            settings[kCFStreamSSLPeerName as String] = expectedCertName
        }
        if customCertEvaluation {
            settings[GCDAsyncSocketManuallyEvaluateTrust] = true
        }
    }
    
    /**
     * Allows a delegate to hook into the TLS handshake and manually validate the peer it's connecting to.
     *
     * This is only called if the stream is secured with settings that include:
     * - GCDAsyncSocketManuallyEvaluateTrust == YES
     * That is, if a delegate implements xmppStream:willSecureWithSettings:, and plugs in that key/value pair.
     *
     * Thus this delegate method is forwarding the TLS evaluation callback from the underlying GCDAsyncSocket.
     *
     * Typically the delegate will use SecTrustEvaluate (and related functions) to properly validate the peer.
     *
     * Note from Apple's documentation:
     *   Because [SecTrustEvaluate] might look on the network for certificates in the certificate chain,
     *   [it] might block while attempting network access. You should never call it from your main thread;
     *   call it only from within a function running on a dispatch queue or on a separate thread.
     *
     * This is why this method uses a completionHandler block rather than a normal return value.
     * The idea is that you should be performing SecTrustEvaluate on a background thread.
     * The completionHandler block is thread-safe, and may be invoked from a background queue/thread.
     * It is safe to invoke the completionHandler block even if the socket has been closed.
     *
     * Keep in mind that you can do all kinds of cool stuff here.
     * For example:
     *
     * If your development server is using a self-signed certificate,
     * then you could embed info about the self-signed cert within your app, and use this callback to ensure that
     * you're actually connecting to the expected dev server.
     *
     * Also, you could present certificates that don't pass SecTrustEvaluate to the client.
     * That is, if SecTrustEvaluate comes back with problems, you could invoke the completionHandler with NO,
     * and then ask the client if the cert can be trusted. This is similar to how most browsers act.
     *
     * Generally, only one delegate should implement this method.
     * However, if multiple delegates implement this method, then the first to invoke the completionHandler "wins".
     * And subsequent invocations of the completionHandler are ignored.
     **/
    
    public func xmppStream(_ sender: XMPPStream, didReceiveTrust trust: SecTrust, completionHandler:
        @escaping (_ shouldTrustPeer: Bool?) -> Void) {
        let bgQueue = DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default)
        
        bgQueue.async(execute: { () -> Void in
            var result: SecTrustResultType =  SecTrustResultType.deny as! SecTrustResultType
            let status = SecTrustEvaluate(trust, &result)
            
            if status == noErr {
                completionHandler(true)
            } else {
                completionHandler(false)
            }
        })
    }
    
    public func xmppStreamDidSecure(_ sender: XMPPStream) {
        //did secure
    }
    
    public func xmppStreamDidConnect(_ sender: XMPPStream) {
        delegate?.xmppConnectionDidConnect?(sender)
        do {
            try stream.authenticate(withPassword: password)
        } catch _ {
            //Handle error
        }
    }
    
    public func xmppStreamDidAuthenticate(_ sender: XMPPStream) {
        delegate?.xmppConnectionDidAuthenticate?(sender)
        goOnline()
    }
    
    public func xmppStream(_ sender: XMPPStream, didNotAuthenticate error: DDXMLElement) {
        delegate?.xmppConnection?(sender, didNotAuthenticate: error)
    }
    
    public func xmppStreamDidDisconnect(_ sender: XMPPStream, withError error: Error) {
        delegate?.xmppConnectionDidDisconnect?(sender, withError: error)
    }
}
