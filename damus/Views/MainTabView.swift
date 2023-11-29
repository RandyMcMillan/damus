//
//  MainTabView.swift
//  damus
//
//  Created by William Casarin on 2022-05-19.
//

import SwiftUI

enum Timeline: String, CustomStringConvertible, Hashable {
    case home
    case notifications
    case search
    case dms
    
    var description: String {
        return self.rawValue
    }
}

func show_indicator(timeline: Timeline, current: NewEventsBits, indicator_setting: Int) -> Bool {
    if timeline == .notifications {
        return (current.rawValue & indicator_setting & NewEventsBits.notifications.rawValue) > 0
    }
    return (current.rawValue & indicator_setting) == timeline_to_notification_bits(timeline, ev: nil).rawValue
}
    
struct TabButton: View {
    let timeline: Timeline
    let img: String
    @Binding var selected: Timeline
    @Binding var new_events: NewEventsBits
    
    let settings: UserSettingsStore
    let action: (Timeline) -> ()
    
    var body: some View {
        ZStack(alignment: .center) {
            Tab
            
            if show_indicator(timeline: timeline, current: new_events, indicator_setting: settings.notification_indicators) {
                Circle()
                    .size(CGSize(width: 8, height: 8))
                    .frame(width: 10, height: 10, alignment: .topTrailing)
                    .alignmentGuide(VerticalAlignment.center) { a in a.height + 2.0 }
                    .alignmentGuide(HorizontalAlignment.center) { a in a.width - 12.0 }
                    .foregroundColor(.accentColor)
            }
        }
    }
    
    var Tab: some View {
        Button(action: {
            action(timeline)
            let bits = timeline_to_notification_bits(timeline, ev: nil)
            new_events = NewEventsBits(rawValue: new_events.rawValue & ~bits.rawValue)
        }) {
            Label("", systemImage: selected == timeline ? "\(img).fill" : img)
                .contentShape(Rectangle())
                .frame(maxWidth: .infinity, minHeight: 30.0)
        }
        .foregroundColor(selected != timeline ? .gray : .primary)
    }
}
    

struct TabBar: View {
    @Binding var new_events: NewEventsBits
    @Binding var selected: Timeline
    
    let settings: UserSettingsStore
    let action: (Timeline) -> ()
    
    var body: some View {
        VStack {
            Divider()
            HStack {
                TabButton(timeline: .home, img: "house", selected: $selected, new_events: $new_events, settings: settings, action: action).keyboardShortcut("1")
                TabButton(timeline: .dms, img: "bubble.left.and.bubble.right", selected: $selected, new_events: $new_events, settings: settings, action: action).keyboardShortcut("2")
                TabButton(timeline: .search, img: "magnifyingglass.circle", selected: $selected, new_events: $new_events, settings: settings, action: action).keyboardShortcut("3")
                TabButton(timeline: .notifications, img: "bell", selected: $selected, new_events: $new_events, settings: settings, action: action).keyboardShortcut("4")
            }
        }
    }
}
