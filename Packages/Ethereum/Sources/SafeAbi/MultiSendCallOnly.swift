// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation
import Solidity

public enum MultiSendCallOnly {
    public struct multiSend: SolContractFunction, SolKeyPathTuple {
        public var transactions: Sol.Bytes

        public static var keyPaths: [AnyKeyPath] = [
            \Self.transactions
        ]

        public init(transactions : Sol.Bytes) {
            self.transactions = transactions
        }

        public init() {
            self.init(transactions: .init())
        }

        public struct Returns: SolEncodableTuple, SolKeyPathTuple {


            public static var keyPaths: [AnyKeyPath] = [

            ]



            public init() {

            }
        }
    }
}
