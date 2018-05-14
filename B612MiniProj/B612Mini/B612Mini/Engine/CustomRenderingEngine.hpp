//
//  CustomRenderingEngine.hpp
//  B612Mini
//
//  Created by JohnHong on 2018. 5. 8..
//  Copyright © 2018년 Naver. All rights reserved.
//

#ifndef CustomRenderingEngine_hpp
#define CustomRenderingEngine_hpp

#include <stdio.h>
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>
#include "gameplay.h"
#include "CustomKuruScene.hpp"


namespace kuru
{
    using namespace gameplay;
    
    class CustomRenderingEngine : public gameplay::Game
    {
    public:
        static CustomRenderingEngine* getInstance();
        CustomRenderingEngine();
        void createFrameAndColorRenderbuffer();
        void initKuruScene();
        bool attachColorAndDepthBuffer();
        void deleteFramebuffer();
        void applyViewport();
        void bindFramebuffer();
        void bindColorRenderbuffer();
        
    protected:
        /**
         * @see Game::initialize
         */
        void initialize();
        
        /**
         * @see Game::finalize
         */
        void finalize();
        
        /**
         * @see Game::update
         */
        void update(float aElapsedTime);
        
        /**
         * @see Game::render
         */
        void render(float aElapsedTime);
        
        
    private:
        GLuint mFramebuffer;
        GLuint mColorRenderbuffer;
        GLuint mDepthRenderbuffer;
        GLint mFramebufferWidth;
        GLint mFramebufferHeight;
        
        CustomKuruScene *mKuruScene;
    };
}


#endif /* CustomRenderingEngine_hpp */
