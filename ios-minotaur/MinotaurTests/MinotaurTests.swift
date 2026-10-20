//
//  MinotaurTests.swift
//  MinotaurTests
//
//  Created by Rork on August 7, 2026.
//

import Foundation
import Testing
@testable import Minotaur

struct MinotaurTests {

    @MainActor @Test func activityReadStatePersistsAndRespectsMembership() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
        defer { try? FileManager.default.removeItem(at: url) }
        let state = AppState(storeURL: url)
        let creatorUpdate = try #require(state.notifications.first { $0.kind == .creatorPost })
        #expect(!state.readActivityIDs.contains(creatorUpdate.id))
        state.markNotificationRead(creatorUpdate)
        #expect(AppState(storeURL: url).readActivityIDs.contains(creatorUpdate.id))
        let owned = SampleData.thread
        state.recordMemberJoined("A new member", in: owned, eventID: "join-test")
        state.recordMemberJoined("A new member", in: owned, eventID: "join-test")
        #expect(state.notifications.filter { $0.id == "join-test" }.count == 1)
        state.recordMemberJoined("Someone", in: SampleData.gravity, eventID: "not-my-group")
        #expect(!state.activityEvents.contains { $0.id == "not-my-group" })
        state.addPost(to: SampleData.nightwing, text: "My own post", tag: .update, photo: nil, sharePublicly: false)
        let post = try #require(state.posts.last)
        state.replies.append(PostReply(postID: post.id, authorName: "Another member", text: "Keep going!"))
        #expect(state.notifications.contains { $0.kind == .reply && $0.postID == post.id })
        state.addReply("My own reply", to: post.id)
        #expect(state.notifications.filter { $0.kind == .reply && $0.postID == post.id }.count == 1)
        state.markAllNotificationsRead()
        #expect(state.unreadNotificationCount == 0)
        #expect(AppState(storeURL: url).unreadNotificationCount == 0)
        state.leave(SampleData.nightwing)
        #expect(!state.notifications.contains { $0.labyrinthID == SampleData.nightwing.id })
    }

    @MainActor @Test func creatorDiscoveryAndFollowingRespectPrivacyAndPersist() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
        defer { try? FileManager.default.removeItem(at: url) }
        let state = AppState(storeURL: url)
        var hidden = SampleData.nightwing
        hidden.id = UUID(); hidden.ownerHandle = "@privatecoach"; hidden.isPublic = false
        state.labyrinths.append(hidden)
        var personal = hidden
        personal.id = UUID(); personal.ownerHandle = "@personalcoach"; personal.isPublic = true; personal.isPersonal = true
        state.labyrinths.append(personal)
        #expect(!state.creators.contains { $0.id == "@privatecoach" || $0.id == "@personalcoach" })
        #expect(SampleData.nightwing.matchesDiscovery("DANE COLE"))
        #expect(SampleData.nightwing.matchesDiscovery("@nightwing"))
        let creator = try #require(state.creators.first { $0.id == "@gaia" })
        #expect(creator.matches("bodyweight"))
        let memberships = state.memberships.count
        state.toggleFollow(creator)
        #expect(state.memberships.count == memberships)
        #expect(AppState(storeURL: url).followedCreators.contains(creator.id))
        state.toggleFollow(creator)
        #expect(!AppState(storeURL: url).followedCreators.contains(creator.id))
        let legacy = StateSnapshot(memberships: [], posts: [], messages: [], ownedLabyrinths: [], dmSettings: [:])
        let decoded = try JSONDecoder().decode(StateSnapshot.self, from: JSONEncoder().encode(legacy))
        #expect(decoded.followedCreators == nil)
    }

    @Test func measurementLabelsAndLegacyDataRemainCompatible() throws {
        var block = ExerciseBlock(name: "Plank", target: "Core", sets: 3, reps: "30", restSeconds: 45)
        #expect(block.targetLabel == "30 reps")
        block.measure = .time
        #expect(block.targetLabel == "30 sec")
        block.reps = "2 min"
        #expect(block.targetLabel == "2 min")
        block.measure = .distance; block.reps = "2 miles"
        #expect(block.targetLabel == "2 miles")
        block.measure = nil
        let data = try JSONEncoder().encode(block)
        let decoded = try JSONDecoder().decode(ExerciseBlock.self, from: data)
        #expect(decoded.measurement == .distance)
        #expect(!decoded.summary.contains("miles reps"))
        block.reps = "30s"
        #expect(block.measurement == .time)
        block.reps = "400m"
        #expect(block.measurement == .distance)
    }

    @MainActor @Test func repliesPersistAndRequireMembership() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
        defer { try? FileManager.default.removeItem(at: url) }
        let state = AppState(storeURL: url)
        let program = SampleData.nightwing
        state.addPost(to: program, text: "Test conversation", tag: .update, photo: nil, sharePublicly: false)
        let post = try #require(state.posts.last)
        #expect(!state.addReply("   ", to: post.id))
        #expect(state.addReply("  A useful reply  ", to: post.id))
        let restored = AppState(storeURL: url)
        #expect(restored.replies.last?.text == "A useful reply")
        #expect(restored.posts.first { $0.id == post.id }?.commentCount == 1)
        // A different creator's program must remain gated for non-members.
        var other = program
        other.id = UUID(); other.ownerHandle = "@someoneelse"
        state.labyrinths.append(other)
        var lockedPost = post
        lockedPost.id = UUID(); lockedPost.labyrinthID = other.id
        state.posts.append(lockedPost)
        #expect(!state.addReply("Not allowed", to: lockedPost.id))
    }

    @MainActor @Test func sessionSnapshotSurvivesProgramEdits() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
        defer { try? FileManager.default.removeItem(at: url) }
        let state = AppState(storeURL: url)
        var program = SampleData.nightwing
        let day = program.days[0]
        let block = try #require(day.blocks.first)
        let record = WorkoutRecord(labyrinthID: program.id, programName: program.name, workoutName: day.title, seconds: 42, completedSets: 1, totalSets: 3, daySnapshot: day, exerciseSets: [block.id.uuidString: 1])
        state.saveWorkout(record, day: day, program: program)
        program.days[0].blocks[0].name = "A changed exercise"
        state.updateLabyrinth(program)
        let saved = try #require(AppState(storeURL: url).history.first)
        #expect(saved.daySnapshot?.blocks.first?.name == block.name)
        #expect(saved.exerciseSets?[block.id.uuidString] == 1)
        #expect(saved.durationLabel == "42s")
        #expect(!saved.isComplete)
    }

    @Test func ongoingLabyrinthRoundTripsThroughLocalPersistence() throws {
        let exercise = ExerciseBlock(
            name: "Push Ups",
            target: "Chest",
            sets: 4,
            reps: "25",
            restSeconds: 45,
            note: "Keep a rigid plank.",
            transitionRestSeconds: 90
        )
        let day = ProgramDay(
            number: 1,
            weekday: "Day 1",
            title: "Push / Pull",
            notes: "Move with control.",
            estimatedMinutes: 35,
            blocks: [exercise],
            recovery: false
        )
        let labyrinth = Labyrinth(
            name: "Endless Engine",
            ownerName: "Alex Rivers",
            ownerHandle: "@alexrivers",
            ownerAvatar: nil,
            tagline: "A repeating cycle.",
            cover: nil,
            weeks: 0,
            daysPerWeek: 1,
            level: "Open",
            category: "Custom",
            price: nil,
            memberCount: 0,
            official: false,
            isPublic: false,
            dmEnabled: true,
            days: [day],
            format: .ongoing
        )

        let data = try JSONEncoder().encode(labyrinth)
        let decoded = try JSONDecoder().decode(Labyrinth.self, from: data)

        #expect(decoded.programFormat == .ongoing)
        #expect(decoded.days.first?.blocks.first?.restSeconds == 45)
        #expect(decoded.days.first?.blocks.first?.transitionRestSeconds == 90)
        #expect(decoded.durationLabel == "Ongoing · 1-day cycle")
    }


    @MainActor @Test func personalWorkoutAndEditsSurviveRelaunch() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
        defer { try? FileManager.default.removeItem(at: url) }
        let state = AppState(storeURL: url)
        var program = SampleData.nightwing
        program.id = UUID()
        program.ownerHandle = state.user.handle
        program.ownerName = state.user.name
        program.isPersonal = true
        program.isPublic = false
        program.format = .ongoing
        program.days = [program.days[0]]
        state.createLabyrinth(program)
        #expect(state.isMember(of: program))
        program.name = "My edited workout"
        state.updateLabyrinth(program)
        let restored = AppState(storeURL: url)
        #expect(restored.labyrinths.first { $0.id == program.id }?.name == "My edited workout")
        #expect(restored.isMember(of: program))
    }

    @MainActor @Test func partialWorkoutIsLoggedWithoutAdvancingAndSaveIsIdempotent() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
        defer { try? FileManager.default.removeItem(at: url) }
        let state = AppState(storeURL: url)
        let program = SampleData.nightwing
        let day = try #require(state.today(in: program))
        let startingDay = state.membership(for: program)?.currentDay
        let total = day.blocks.reduce(0) { $0 + $1.sets }
        let record = WorkoutRecord(labyrinthID: program.id, programName: program.name, workoutName: day.title, seconds: 180, completedSets: 1, totalSets: total)
        state.saveWorkout(record, day: day, program: program)
        state.saveWorkout(record, day: day, program: program)
        #expect(state.history.count == 1)
        #expect(state.membership(for: program)?.currentDay == startingDay)
        let full = WorkoutRecord(labyrinthID: program.id, programName: program.name, workoutName: day.title, seconds: 600, completedSets: total, totalSets: total)
        state.saveWorkout(full, day: day, program: program)
        #expect(state.membership(for: program)?.completedDays.contains(day.number) == true)
        #expect(AppState(storeURL: url).history.count == 2)
    }

    @MainActor @Test func progressRequiresExplicitConsentAndPublicProgram() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
        defer { try? FileManager.default.removeItem(at: url) }
        let state = AppState(storeURL: url)
        let program = SampleData.nightwing
        state.addPost(to: program, text: "Private progress", tag: .progress, photo: .asset("man_fitness_after_photo"), sharePublicly: false)
        let privatePost = try #require(state.posts.last)
        #expect(privatePost.pair != nil)
        #expect(!state.hypedTransformations.contains { $0.id == privatePost.id })
        state.addPost(to: program, text: "Shared progress", tag: .progress, photo: .asset("man_fitness_after_photo"), sharePublicly: true)
        let publicPost = try #require(state.posts.last)
        #expect(state.hypedTransformations.contains { $0.id == publicPost.id })
        #expect(SampleData.featuredTransformationPosts.allSatisfy { $0.discoveryConsent == true })
    }

    @MainActor @Test func restScheduleAndPreferencesPersist() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
        defer { try? FileManager.default.removeItem(at: url) }
        let state = AppState(storeURL: url)
        let weekday = String(Calendar.current.component(.weekday, from: Date()))
        state.setSchedule([weekday: ScheduleSlot()])
        var preference = TrainingPreferences()
        preference.goal = "Get stronger"
        state.setPreferences(preference)
        let restored = AppState(storeURL: url)
        #expect(restored.todaySlot != nil)
        #expect(restored.scheduledProgram == nil)
        #expect(restored.preferences.goal == "Get stronger")
    }

    @MainActor @Test func editingFixedProgramPreservesLaterSessions() throws {
        let program = SampleData.nightwing
        let draft = LabyrinthDraft(program)
        let edited = draft.makeLabyrinth(owner: SampleData.user)
        #expect(edited.days.count == program.days.count)
        #expect(edited.days.map(\.title) == program.days.map(\.title))
        #expect(edited.days.map(\.blocks.count) == program.days.map(\.blocks.count))
        #expect(edited.id == program.id)
        #expect(edited.daysPerWeek == program.daysPerWeek)
    }

    @MainActor @Test func ongoingCycleWrapsAfterLastDay() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
        defer { try? FileManager.default.removeItem(at: url) }
        let state = AppState(storeURL: url)
        var program = SampleData.nightwing
        program.id = UUID(); program.isPersonal = true; program.format = .ongoing
        program.days = [program.days[0]]
        state.createLabyrinth(program)
        state.completeDay(program.days[0], in: program, duration: 20, volume: 0)
        #expect(state.membership(for: program)?.currentDay == 1)
        #expect(state.membership(for: program)?.completedDays.isEmpty == true)
    }

}
