//
//  RenderingEngine.hpp
//  B612Mini
//
//  Created by JohnHong on 2018. 2. 8..
//  Copyright © 2018년 Naver. All rights reserved.
//

#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>
#include "gameplay.h"


#ifndef RenderingEngine_hpp
#define RenderingEngine_hpp

#include <stdio.h>
#include "KuruScene.hpp"

namespace kuru
{
    
    class RenderingEngine: public gameplay::Game
    {
    public:
        static RenderingEngine* getInstance();
        RenderingEngine();
        void initPrevAllocFramebuffer();
        void initializeForCustom();
        bool isRunning();
        bool isPause();
        void processPrevRendering(float aWidth, float aHeight);
        
    protected:
        /**
         * Initialize callback that is called just before the first frame when the game starts.
         */
        void initialize();
        
        /**
         * Finalize callback that is called when the game on exits.
         */
        void finalize();
        
        /**
         * Update callback for handling update routines.
         *
         * Called just before render, once per frame when game is running.
         * Ideal for non-render code and game logic such as input and animation.
         *
         * @param aElapsedTime The elapsed game time.
         */
        void update(float aElapsedTime);
        
        /**
         * Render callback for handling rendering routines.
         *
         * Called just after update, once per frame when game is running.
         * Ideal for all rendering code.
         *
         * @param aElapsedTime The elapsed game time.
         */
        void render(float aElapsedTime);
        
    private:
        GLuint mFramebuffer;
        GLuint mColorRenderbuffer;
        GLint mFramebufferWidth;
        GLint mFramebufferHeight;
        KuruScene *mKuruScene;
    };
}

#endif /* RenderingEngine_hpp */
