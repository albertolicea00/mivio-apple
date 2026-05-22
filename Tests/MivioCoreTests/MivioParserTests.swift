import XCTest
@testable import MivioCore

final class MivioParserTests: XCTestCase {
    
    func testMovieParsingStandard() {
        let fileName = "Inception.2010.1080p.BluRay.x264.mkv"
        let parsed = MivioGuessItParser.parse(fileName: fileName)
        
        XCTAssertEqual(parsed.title, "Inception")
        XCTAssertEqual(parsed.year, 2010)
        XCTAssertEqual(parsed.season, nil)
        XCTAssertEqual(parsed.episode, nil)
        XCTAssertEqual(parsed.resolution, "1080P")
        XCTAssertEqual(parsed.codec, "H.264")
        XCTAssertEqual(parsed.type, .movie)
    }
    
    func testEpisodeParsingStandard() {
        let fileName = "Stranger.Things.S01E03.720p.HEVC.mp4"
        let parsed = MivioGuessItParser.parse(fileName: fileName)
        
        XCTAssertEqual(parsed.title, "Stranger Things")
        XCTAssertEqual(parsed.year, nil)
        XCTAssertEqual(parsed.season, 1)
        XCTAssertEqual(parsed.episode, 3)
        XCTAssertEqual(parsed.resolution, "720P")
        XCTAssertEqual(parsed.codec, "H.265")
        XCTAssertEqual(parsed.type, .episode)
    }
    
    func testEpisodeParsingAlternative() {
        let fileName = "Breaking_Bad_5x04_x264_1080p.mkv"
        let parsed = MivioGuessItParser.parse(fileName: fileName)
        
        XCTAssertEqual(parsed.title, "Breaking Bad")
        XCTAssertEqual(parsed.year, nil)
        XCTAssertEqual(parsed.season, 5)
        XCTAssertEqual(parsed.episode, 4)
        XCTAssertEqual(parsed.resolution, "1080P")
        XCTAssertEqual(parsed.codec, "H.264")
        XCTAssertEqual(parsed.type, .episode)
    }
    
    func testMovieWithSpacesAndYear() {
        let fileName = "The Matrix 1999 2160p UHD.mkv"
        let parsed = MivioGuessItParser.parse(fileName: fileName)
        
        XCTAssertEqual(parsed.title, "The Matrix")
        XCTAssertEqual(parsed.year, 1999)
        XCTAssertEqual(parsed.season, nil)
        XCTAssertEqual(parsed.episode, nil)
        XCTAssertEqual(parsed.resolution, "4K")
        XCTAssertEqual(parsed.type, .movie)
    }
}
