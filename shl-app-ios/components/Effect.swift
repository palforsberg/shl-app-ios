//
//  Effect.swift
//  shl-app-ios
//
//  Created by Pål on 2022-09-30.
//

import SwiftUI

struct Particle: Hashable {
    var pos: UnitPoint
    var vec: UnitPoint = UnitPoint(x: 0.01, y: -0.01)
    var creationDate = Date.now.timeIntervalSinceReferenceDate
}

class ParticleSystem {
    let image = Image(uiImage: UIImage(named: "launch-puck-2")!)
    var particles: [Particle]
    var center = UnitPoint.center
    
    init() {
        particles = [
            Particle(pos: center, vec: UnitPoint(x: 0.01, y: -0.01)),
            Particle(pos: center, vec: UnitPoint(x: 0.00, y: -0.015)),
            Particle(pos: center, vec: UnitPoint(x: -0.01, y: -0.012)),
        ]
    }
    
    func update(date: TimeInterval) {
        particles = particles.map({ p in
            Particle(
                pos: UnitPoint(x: p.pos.x + p.vec.x, y: p.pos.y + p.vec.y),
                vec: UnitPoint(x: p.vec.x * 0.9, y: p.vec.y * 0.9),
                creationDate: p.creationDate)
        })
    }
}


struct Effect: View {
    @State private var particleSystem = ParticleSystem()
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let timelineDate = timeline.date.timeIntervalSinceReferenceDate
                particleSystem.update(date: timelineDate)

                for particle in particleSystem.particles {
                    let age = (timelineDate - particle.creationDate)
                    let invAge = 1 - (age * 2)
                    let xPos = particle.pos.x * size.width
                    let yPos = particle.pos.y * size.height
                    
                    context.opacity = invAge
                    context.draw(particleSystem.image, in: CGRect(x: xPos, y: yPos, width: 20, height: 20))
                }
            }
        }
        .ignoresSafeArea()
        .task {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                self.particleSystem = ParticleSystem()
            }
        }
    }
}

/*
struct MultiText: View {
    @State private var text: String
    var lines: [String]
    init(lines: [String]) {
        self.lines = lines
        self.text = lines[0]
    }
    
    var body: some View {
        Text(text)
            .animation(.easeOut(duration: 0.6).repeatForever(), value: text)
            .onAppear {
                withAnimation {
                    text = self.lines[1]
                }
            }
    }
        
}
 
*/

struct Effect_Previews: PreviewProvider {
    static var previews: some View {
     Effect()
    }
}
