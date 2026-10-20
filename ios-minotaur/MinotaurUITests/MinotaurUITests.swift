import XCTest

final class MinotaurUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor private func launch(_ appearance: String = "Light", largeText: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["MINOTAUR_TEST_STATE"] = "ui-" + UUID().uuidString
        app.launchArguments = ["-completedOrientation", "YES", "-appearance", appearance]
        if largeText { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launch()
        XCTAssertTrue(app.buttons["findPlan"].waitForExistence(timeout: 10))
        return app
    }
    @MainActor private func capture(_ name: String) {
        // Capture the settled native screen rather than a frame inside a control transition.
        Thread.sleep(forTimeInterval: 1)
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor func testNotificationsInboxAndDeepLinks() {
        let app = launch()
        let bell = app.buttons["notifications"]
        XCTAssertTrue(bell.exists)
        XCTAssertTrue((bell.value as? String ?? "").contains("unread"))
        bell.tap()
        XCTAssertTrue(app.navigationBars["Notifications"].waitForExistence(timeout: 5))
        capture("41-notifications-light")
        let creatorPost = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'notification-post-'")).firstMatch
        XCTAssertTrue(creatorPost.waitForExistence(timeout: 5))
        creatorPost.tap()
        XCTAssertTrue(app.navigationBars["Post & replies"].waitForExistence(timeout: 5))
        app.navigationBars.buttons.firstMatch.tap()
        let join = app.buttons["notification-demo-member-joined"]
        XCTAssertTrue(join.waitForExistence(timeout: 5))
        join.tap()
        XCTAssertTrue(app.segmentedControls.buttons["Community"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.segmentedControls.buttons["Community"].isSelected)
        app.navigationBars.buttons.firstMatch.tap()
        app.buttons["markNotificationsRead"].tap()
        app.segmentedControls["notificationFilter"].buttons["Unread"].tap()
        XCTAssertTrue(app.staticTexts["You’re all caught up"].waitForExistence(timeout: 5))
        capture("42-notifications-read")
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertEqual(app.buttons["notifications"].value as? String, "All read")
    }

    @MainActor func testScrollReactiveGlassEdges() {
        for appearance in ["Light", "Dark"] {
            let app = launch(appearance)
            capture("glass-\(appearance.lowercased())-rest")
            let lower = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.70))
            let upper = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.52))
            lower.press(forDuration: 0.05, thenDragTo: upper)
            capture("glass-\(appearance.lowercased())-scrolled")
            upper.press(forDuration: 0.05, thenDragTo: lower)
            capture("glass-\(appearance.lowercased())-return")
            let start = app.buttons["startToday"]
            XCTAssertTrue(start.isHittable)
            start.tap()
            XCTAssertTrue(app.buttons["completeSet"].waitForExistence(timeout: 5))
            app.terminate()
        }
    }

    @MainActor func testCreatorDiscoveryFollowAndCommunityPreview() {
        let app = launch()
        app.buttons["findPlan"].tap()
        app.segmentedControls["discoveryScope"].buttons["Creators"].tap()
        capture("30-creators-light")
        let search = app.searchFields.firstMatch
        search.tap(); search.typeText("Dane Cole")
        app.keyboards.buttons["Search"].tap()
        let creator = app.buttons["creator-@nightwing"]
        XCTAssertTrue(creator.waitForExistence(timeout: 5))
        creator.tap()
        let follow = app.buttons["followCreator"]
        XCTAssertTrue(follow.waitForExistence(timeout: 5))
        follow.tap()
        XCTAssertTrue(follow.label.contains("Following"))
        capture("31-creator-profile-light")
        app.navigationBars.buttons.firstMatch.tap()
        app.tabBars.buttons["Profile"].tap()
        app.buttons["followingCreators"].tap()
        XCTAssertTrue(app.staticTexts["Dane Cole"].waitForExistence(timeout: 5))
        capture("32-following")
        app.tabBars.buttons["Explore"].tap()
        if app.buttons["Clear text"].exists { app.buttons["Clear text"].tap() }
        if app.buttons["Close"].exists { app.buttons["Close"].tap() }
        app.segmentedControls["discoveryScope"].buttons["Communities"].tap()
        capture("33-communities")
        app.staticTexts["Titan Strength"].tap()
        XCTAssertTrue(app.staticTexts["Train together"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Join this Labyrinth"].exists)
        capture("34-community-preview")
    }

    @MainActor func testCreatorDarkPaidPreviewAndLargeText() {
        let app = launch("Dark")
        app.buttons["findPlan"].tap()
        app.segmentedControls["discoveryScope"].buttons["Creators"].tap()
        capture("35-creators-dark")
        app.buttons["creator-@gaia"].tap()
        XCTAssertTrue(app.buttons["followCreator"].waitForExistence(timeout: 5))
        capture("36-creator-dark")
        app.swipeUp()
        let program = app.staticTexts["Gravity Breaker"].firstMatch
        for _ in 0..<3 where !program.isHittable { app.swipeUp() }
        program.tap()
        app.segmentedControls.buttons["Community"].tap()
        let paid = app.buttons["Preview membership"]
        for _ in 0..<3 where !paid.isHittable { app.swipeUp() }
        XCTAssertTrue(paid.isHittable)
        capture("37-paid-community-dark")
        paid.tap()
        XCTAssertTrue(app.alerts["Preview membership"].waitForExistence(timeout: 5))
        app.alerts.buttons["Not now"].tap()
        XCTAssertFalse(app.buttons["Write a post"].exists)
        app.terminate()
        let large = launch("Light", largeText: true)
        large.buttons["findPlan"].tap()
        let scope = large.buttons["discoveryScope"]
        for _ in 0..<2 where !scope.isHittable { large.swipeUp() }
        scope.tap()
        large.buttons["Creators"].tap()
        capture("38-creators-large-text")
        let creator = large.buttons["creator-@nightwing"]
        for _ in 0..<5 where !creator.isHittable { large.swipeUp() }
        creator.tap()
        capture("39-creator-large-text")
        let follow = large.buttons["followCreator"]
        for _ in 0..<5 where !follow.isHittable { large.swipeUp() }
        XCTAssertTrue(follow.isHittable)
        follow.tap()
        XCTAssertTrue(follow.label.contains("Following"))
        capture("40-creator-follow-large-text")
    }

    @MainActor func testDiscoveryAndCommunityGate() {
        let app = launch()
        capture("01-home-light")
        app.buttons["findPlan"].tap()
        XCTAssertTrue(app.navigationBars["Explore"].waitForExistence(timeout: 5))
        capture("02-explore-light")
        app.buttons["exploreFilters"].tap()
        XCTAssertTrue(app.staticTexts["Your kind of training"].waitForExistence(timeout: 5))
        capture("03-filters")
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Show '")).firstMatch.tap()
        app.swipeUp()
        // All sample programs remain navigable even when filters are unused.
        XCTAssertTrue(app.tabBars.buttons["Profile"].exists)
        app.tabBars.buttons["Profile"].tap()
        XCTAssertTrue(app.navigationBars["Your space"].waitForExistence(timeout: 5))
        capture("04-profile-light")
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        capture("05-settings")
    }

    @MainActor func testPersonalWorkoutCreateSaveStartAndLog() {
        let app = launch()
        app.buttons["buildWorkout"].tap()
        XCTAssertTrue(app.textFields["workoutName"].waitForExistence(timeout: 5))
        app.textFields["workoutName"].tap()
        app.textFields["workoutName"].typeText("Morning movement")
        app.swipeUp()
        let add = app.buttons["addExercise"]
        if !add.isHittable { app.swipeUp() }
        add.tap()
        XCTAssertTrue(app.textFields["Exercise"].waitForExistence(timeout: 5))
        let field = app.textFields["Exercise"]
        field.tap()
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: (field.value as? String ?? "").count) + "Push-ups")
        capture("06-exercise-editor")
        app.buttons["Save exercise"].tap()
        XCTAssertTrue(app.buttons["savePersonalWorkout"].waitForExistence(timeout: 5))
        capture("07-workout-builder")
        app.buttons["savePersonalWorkout"].tap()
        XCTAssertTrue(app.buttons["startProgram"].waitForExistence(timeout: 5))
        capture("08-personal-workout")
        app.buttons["startProgram"].tap()
        XCTAssertTrue(app.buttons["completeSet"].waitForExistence(timeout: 5))
        capture("09-active-workout")
        app.buttons["completeSet"].tap()
        XCTAssertTrue(app.buttons["Skip rest"].waitForExistence(timeout: 3))
        app.buttons["Skip rest"].tap()
        app.buttons["Close workout"].tap()
        app.buttons["Save completed sets"].tap()
        XCTAssertTrue(app.navigationBars["Session saved"].waitForExistence(timeout: 5))
        capture("10-session-summary")
        XCTAssertTrue(app.staticTexts["Every set counts."].exists)
        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["startProgram"].waitForExistence(timeout: 5))
        app.tabBars.buttons["Profile"].tap()
        let history = app.buttons["workoutHistory"]
        for _ in 0..<4 where !history.isHittable { app.swipeUp() }
        history.tap()
        XCTAssertTrue(app.navigationBars["Workout history"].waitForExistence(timeout: 5))
        app.staticTexts["Morning movement"].tap()
        XCTAssertTrue(app.navigationBars["Session details"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Push-ups"].exists)
        capture("24-session-history")
    }

    @MainActor func testTrainingLibraryAndPersistentRestControls() {
        let app = launch()
        app.buttons["allTraining"].tap()
        XCTAssertTrue(app.navigationBars["Your training"].waitForExistence(timeout: 5))
        capture("21-training-library")
        app.buttons["libraryFilter"].tap()
        app.buttons["My workouts"].tap()
        XCTAssertTrue(app.staticTexts["No workouts here yet"].exists)
        app.navigationBars.buttons.firstMatch.tap()
        app.buttons["startToday"].tap()
        app.buttons["completeSet"].tap()
        XCTAssertTrue(app.buttons["Skip rest"].isHittable)
        capture("22-rest-controls")
        app.buttons["+30 seconds"].tap()
        app.buttons["Skip rest"].tap()
        XCTAssertTrue(app.buttons["completeSet"].isEnabled)
    }

    @MainActor func testCommunityReply() {
        let app = launch()
        app.buttons["findPlan"].tap()
        app.staticTexts["Full body foundations"].tap()
        app.segmentedControls.buttons["Community"].tap()
        app.buttons["Join this Labyrinth"].tap()
        app.buttons["Skip for now"].tap()
        app.buttons["Introduce yourself"].tap()
        let editor = app.textViews.firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        editor.tap(); editor.typeText("Ready for my first session.")
        app.swipeUp()
        app.buttons["Post to community"].tap()
        let replies = app.buttons["View replies, 0 comments"]
        XCTAssertTrue(replies.waitForExistence(timeout: 5))
        replies.tap()
        XCTAssertTrue(app.navigationBars["Post & replies"].waitForExistence(timeout: 5))
        let field = app.textFields["replyText"]
        field.tap(); field.typeText("One workout at a time.")
        app.buttons["Send reply"].tap()
        XCTAssertTrue(app.staticTexts["One workout at a time."].waitForExistence(timeout: 5))
        capture("23-post-replies")
    }

    @MainActor func testTimedTargetAndLargeTextRest() {
        let app = launch()
        app.buttons["buildWorkout"].tap()
        app.textFields["workoutName"].tap()
        app.textFields["workoutName"].typeText("Core practice")
        app.swipeUp()
        app.buttons["addExercise"].tap()
        app.segmentedControls["exerciseMeasure"].buttons["Time"].tap()
        let target = app.textFields["Time"]
        target.tap()
        target.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: (target.value as? String ?? "").count) + "30 sec")
        app.buttons["Save exercise"].tap()
        XCTAssertTrue(app.staticTexts["3 sets · 30 sec · 60s rest"].exists)
        capture("25-timed-exercise")
        app.buttons["savePersonalWorkout"].tap()
        app.buttons["startProgram"].tap()
        XCTAssertTrue(app.staticTexts["30 sec"].exists)
        app.terminate()
        let large = launch("Dark", largeText: true)
        let start = large.buttons["startToday"]
        if !start.isHittable { large.swipeUp() }
        start.tap()
        large.buttons["completeSet"].tap()
        XCTAssertTrue(large.buttons["Skip rest"].isHittable)
        capture("26-rest-accessibility")
    }

    @MainActor func testDarkAppearanceAndLargeText() {
        let app = launch("Dark")
        capture("11-home-dark")
        app.buttons["startToday"].tap()
        XCTAssertTrue(app.buttons["completeSet"].waitForExistence(timeout: 5))
        capture("12-workout-dark")
        app.terminate()
        let large = launch("Light", largeText: true)
        capture("13-home-accessibility")
        large.buttons["buildWorkout"].tap()
        XCTAssertTrue(large.textFields["workoutName"].waitForExistence(timeout: 5))
        capture("14-builder-accessibility")
    }

    @MainActor func testMembershipAndFullProgramBuilder() {
        let app = launch()
        app.buttons["findPlan"].tap()
        let program = app.staticTexts["Full body foundations"]
        XCTAssertTrue(program.waitForExistence(timeout: 5))
        program.tap()
        app.segmentedControls.buttons["Community"].tap()
        XCTAssertTrue(app.staticTexts["Stronger together"].waitForExistence(timeout: 5))
        capture("15-membership-gate")
        app.buttons["Join this Labyrinth"].tap()
        XCTAssertTrue(app.buttons["Skip for now"].waitForExistence(timeout: 5))
        app.buttons["Skip for now"].tap()
        XCTAssertTrue(app.segmentedControls.buttons["General"].waitForExistence(timeout: 5))
        capture("16-community")
        app.tabBars.buttons["Profile"].tap()
        let create = app.buttons["Create a Labyrinth"]
        if !create.isHittable { app.swipeUp() }
        create.tap()
        let name = app.textFields["Name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap(); name.typeText("Weekend flow")
        app.buttons["Continue"].tap()
        XCTAssertTrue(app.buttons["Ongoing"].waitForExistence(timeout: 5))
        app.buttons["Ongoing"].tap()
        app.buttons["Remove"].tap()
        app.buttons["Remove"].tap()
        XCTAssertTrue(app.staticTexts["1 day"].exists)
        app.buttons["Add day"].tap()
        XCTAssertTrue(app.staticTexts["2 days"].exists)
        app.buttons["Remove"].tap()
        capture("17-program-structure")
        app.buttons["Continue"].tap()
        app.buttons["Add exercise"].tap()
        XCTAssertTrue(app.textFields["Exercise"].waitForExistence(timeout: 5))
        app.buttons["Save exercise"].tap()
        capture("18-program-blocks")
        app.buttons["Continue"].tap()
        XCTAssertTrue(app.buttons["Create Labyrinth"].waitForExistence(timeout: 5))
        capture("19-program-review")
        app.buttons["Create Labyrinth"].tap()
        XCTAssertTrue(app.buttons["startProgram"].waitForExistence(timeout: 5))
        app.buttons["Edit workout"].tap()
        XCTAssertTrue(app.textFields["Name"].waitForExistence(timeout: 5))
        capture("20-edit-program")
    }


    @MainActor func testFirstRunOrientation() {
        let app = XCUIApplication()
        app.launchEnvironment["MINOTAUR_TEST_STATE"] = "orientation-" + UUID().uuidString
        app.launchArguments = ["-completedOrientation", "NO", "-appearance", "Light"]
        app.launch()
        XCTAssertTrue(app.buttons["onboardingDone"].waitForExistence(timeout: 10))
        capture("00-orientation")
        app.buttons["onboardingDone"].tap()
        XCTAssertTrue(app.buttons["findPlan"].waitForExistence(timeout: 5))
    }

}
