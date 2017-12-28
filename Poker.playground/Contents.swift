
import Foundation

extension Array {
    var shuffled: Array {
        var copied = Array(self)
        copied.shuffle()
        return copied
    }

    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
    
    subscript(safe bounds: CountableRange<Int>) -> ArraySlice<Element>? {
        return indices.contains(bounds.lowerBound) && indices.contains(bounds.upperBound) ? self[bounds] : nil
    }
    
    subscript(safe bounds: CountableClosedRange<Int>) -> ArraySlice<Element>? {
        return indices.contains(bounds.lowerBound) && indices.contains(bounds.upperBound) ? self[bounds] : nil
    }
    
    mutating func shuffle() {
        let count = self.count
        guard count > 1 else {
            return
        }
        
        var indexDistance: Int
        var targetIndex: Int
        for (firstUnshuffled, unshuffledCount) in zip(indices, stride(from: count, to: 1, by: -1)) {
            indexDistance = numericCast(arc4random_uniform(numericCast(unshuffledCount)))
            targetIndex = index(firstUnshuffled, offsetBy: indexDistance)
            swapAt(firstUnshuffled, targetIndex)
        }
    }
}

extension Array where Element == Trump {
    var description: String {
        return map { $0.description }.joined(separator: ",")
    }
}

protocol Enumerable {}
extension Enumerable where Self: Hashable {
    static var cases: [Self] {
        var n = 0
        return Array(AnyIterator {
            defer {
                n += 1
            }
            let next = withUnsafePointer(to: &n) {
                UnsafeRawPointer($0).assumingMemoryBound(to: Self.self).pointee
            }
            return next.hashValue == n ? next : nil
        })
    }
}

struct Trump {
    enum Suit: String, Enumerable {
        case spade = "♠️"
        case club = "♣️"
        case diamond = "🔶"
        case heart = "🧡"
    }
    
    static let rankRange = 1...13
    
    let suit: Suit
    let rank: Int
    
    var description: String {
        return "(\(suit.rawValue) : \(rank))"
    }
    
    init(suit: Suit, rank: Int) {
        self.suit = suit
        self.rank = Trump.rankRange ~= rank ? rank : 1
    }
}

struct Poker {
    enum HandRank {
        case none
        case straightFlush(Bool)
        case fourOfAKind
        case fullHouse
        case flush
        case straight
        case threeOfAKind
        case twoPair
        case onePair
        case highCards
        
        var text: String {
            switch self {
            case .none:
                return "不成立"
            case .straightFlush(true):
                return "ロイヤルフラッシュ"
            case .straightFlush(false):
                return "ストレートフラッシュ"
            case .fourOfAKind:
                return "4カード"
            case .fullHouse:
                return "フルハウス"
            case .flush:
                return "フラッシュ"
            case .straight:
                return "ストレート"
            case .threeOfAKind:
                return "3カード"
            case .twoPair:
                return "2ペア"
            case .onePair:
                return "1ペア"
            case .highCards:
                return "ブタ"
            }
        }
    }
    
    typealias CardType = Trump
    
    static let handsCount = 5
    
    static func showDown(hands: [CardType]) -> HandRank {
        guard hands.count == handsCount else {
            return .none
        }
        
        let sortedHands = hands.sorted { $0.rank < $1.rank }
        let sortedSameRankCounts = sameRankCount(hands: sortedHands).values.sorted { $0 > $1 }
        
        guard let highHandRank = sortedHands.first?.rank,
            let lowHandRank = sortedHands[safe: 1]?.rank,
            let highSameRankCount = sortedSameRankCounts.first,
            let lowSameRankCount = sortedSameRankCounts[safe: 1] else {
            return .none
        }
        
        let containsFlush = self.containsFlush(hands: sortedHands)
        let containsStraight = self.containsStraight(hands: sortedHands)
        
        switch (containsFlush, containsStraight, highHandRank, lowHandRank, highSameRankCount, lowSameRankCount) {
        case (true, true, 1, 10, _, _):
            return .straightFlush(true)
        case (true, true, _, _, _, _):
            return .straightFlush(false)
        case (_, _, _, _, 4, _):
            return .fourOfAKind
        case (_, _, _, _, 3, 2):
            return .fullHouse
        case (_, true, _, _, _, _):
            return .flush
        case (true, _, _, _, _, _):
            return .straight
        case (_, _, _, _, 3, _):
            return .threeOfAKind
        case (_, _, _, _, 2, 2):
            return .twoPair
        case (_, _, _, _, 2, _):
            return .onePair
        default:
            return .highCards
        }
    }
    
    private static func sameRankCount(hands: [CardType]) -> [Int: Int] {
        return hands.reduce(into: [:]) { $0[$1.rank, default: 0] += 1 }
    }
    
    private static func containsFlush(hands: [CardType]) -> Bool {
        let suit = hands.first?.suit
        return hands.filter({ $0.suit == suit }).count == hands.count
    }
    
    private static func containsStraight(hands: [CardType]) -> Bool {
        var containsStraight = true
        
        for (index, hand) in hands.enumerated() {
            guard let nextRank = hands[safe: index + 1]?.rank else {
                break
            }

            if hand.rank + 1 == nextRank || (hand.rank == 1 && nextRank == 10) {
                continue
            }
            
            containsStraight = false
            break
        }
        
        return containsStraight
    }
}

let decks: [Poker.CardType] = {
    var decks = [Poker.CardType]()
    for suit in Poker.CardType.Suit.cases {
        for rank in Poker.CardType.rankRange {
            decks.append(Poker.CardType(suit: suit, rank: rank))
        }
    }
    return decks
}()

let hands: [Poker.CardType] = {
    guard let hands = decks.shuffled[safe: 0..<Poker.handsCount] else {
        return []
    }
    return Array(hands)
}()
print("\(hands.description)\n= \(Poker.showDown(hands: hands).text)")

let loyalFlushHands = [
    Poker.CardType(suit: .spade, rank: 1),
    Poker.CardType(suit: .spade, rank: 10),
    Poker.CardType(suit: .spade, rank: 11),
    Poker.CardType(suit: .spade, rank: 12),
    Poker.CardType(suit: .spade, rank: 13),
]
print("\(loyalFlushHands.description)\n= \(Poker.showDown(hands: loyalFlushHands).text)")

let straightFlushHands = [
    Poker.CardType(suit: .diamond, rank: 2),
    Poker.CardType(suit: .diamond, rank: 3),
    Poker.CardType(suit: .diamond, rank: 4),
    Poker.CardType(suit: .diamond, rank: 5),
    Poker.CardType(suit: .diamond, rank: 6),
]
print("\(straightFlushHands.description)\n= \(Poker.showDown(hands: straightFlushHands).text)")

let fourOfAKindHands = [
    Poker.CardType(suit: .club, rank: 7),
    Poker.CardType(suit: .spade, rank: 7),
    Poker.CardType(suit: .diamond, rank: 7),
    Poker.CardType(suit: .heart, rank: 7),
    Poker.CardType(suit: .diamond, rank: 8),
]
print("\(fourOfAKindHands.description)\n= \(Poker.showDown(hands: fourOfAKindHands).text)")

let fullHouseHands = [
    Poker.CardType(suit: .club, rank: 3),
    Poker.CardType(suit: .spade, rank: 9),
    Poker.CardType(suit: .diamond, rank: 3),
    Poker.CardType(suit: .heart, rank: 3),
    Poker.CardType(suit: .diamond, rank: 9),
]
print("\(fullHouseHands.description)\n= \(Poker.showDown(hands: fullHouseHands).text)")

let flushHands = [
    Poker.CardType(suit: .heart, rank: 1),
    Poker.CardType(suit: .heart, rank: 3),
    Poker.CardType(suit: .heart, rank: 5),
    Poker.CardType(suit: .heart, rank: 6),
    Poker.CardType(suit: .heart, rank: 13),
]
print("\(flushHands.description)\n= \(Poker.showDown(hands: flushHands).text)")

let straightHands = [
    Poker.CardType(suit: .club, rank: 1),
    Poker.CardType(suit: .spade, rank: 10),
    Poker.CardType(suit: .diamond, rank: 11),
    Poker.CardType(suit: .heart, rank: 12),
    Poker.CardType(suit: .diamond, rank: 13),
]
print("\(straightHands.description)\n= \(Poker.showDown(hands: straightHands).text)")

let threeOfAKindHands = [
    Poker.CardType(suit: .heart, rank: 1),
    Poker.CardType(suit: .spade, rank: 3),
    Poker.CardType(suit: .heart, rank: 1),
    Poker.CardType(suit: .spade, rank: 1),
    Poker.CardType(suit: .heart, rank: 13),
]
print("\(threeOfAKindHands.description)\n= \(Poker.showDown(hands: threeOfAKindHands).text)")

let twoPairHands = [
    Poker.CardType(suit: .heart, rank: 9),
    Poker.CardType(suit: .diamond, rank: 3),
    Poker.CardType(suit: .heart, rank: 12),
    Poker.CardType(suit: .spade, rank: 12),
    Poker.CardType(suit: .diamond, rank: 3),
]
print("\(twoPairHands.description)\n= \(Poker.showDown(hands: twoPairHands).text)")

let onePairHands = [
    Poker.CardType(suit: .heart, rank: 9),
    Poker.CardType(suit: .diamond, rank: 7),
    Poker.CardType(suit: .spade, rank: 12),
    Poker.CardType(suit: .spade, rank: 12),
    Poker.CardType(suit: .diamond, rank: 3),
]
print("\(onePairHands.description)\n= \(Poker.showDown(hands: onePairHands).text)")

let highCardsHands = [
    Poker.CardType(suit: .diamond, rank: 3),
    Poker.CardType(suit: .diamond, rank: 7),
    Poker.CardType(suit: .diamond, rank: 11),
    Poker.CardType(suit: .spade, rank: 12),
    Poker.CardType(suit: .diamond, rank: 5),
]
print("\(highCardsHands.description)\n= \(Poker.showDown(hands: highCardsHands).text)")
