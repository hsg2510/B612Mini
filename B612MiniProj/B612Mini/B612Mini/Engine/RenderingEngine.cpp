//
//  RenderingEngine.cpp
//  B612Mini
//
//  Created by JohnHong on 2018. 2. 8..
//  Copyright © 2018년 Naver. All rights reserved.
//

#include "RenderingEngine.hpp"

using namespace kuru;
using namespace gameplay;

static kuru::RenderingEngine* mEngineInstance = nullptr;

RenderingEngine gEngine;

RenderingEngine* RenderingEngine::getInstance()
{
    if (mEngineInstance == nullptr)
    {
        mEngineInstance = new RenderingEngine();
    }
    
    return mEngineInstance;
}

RenderingEngine::RenderingEngine() : Game()
{
    
}


void RenderingEngine::initPrevAllocFramebuffer()
{
    glGenFramebuffers(1, &mFramebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, mFramebuffer);
    
    glGenRenderbuffers(1, &mColorRenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, mColorRenderbuffer);
    
    std::cout<< "[2]!!!" << std::endl;
}

void RenderingEngine::initializeForCustom()
{
    // color buffer를 frame buffer에 attach 한다.
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, mColorRenderbuffer);
    
    // get frameBuffer size
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &mFramebufferWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &mFramebufferHeight);
    
    
    
//    glViewport(0, 0, aWidth, aHeight);
    
    
    //TODO : 나중에 scene에 addNode 하는식으로 바꿔야 한다.
    mKuruScene = new KuruScene(0.5625, Game::getViewport());
    
    std::cout<< "[4]!!!" << std::endl;
}


bool RenderingEngine::isRunning()
{
    return (Game::getState() == Game::State::RUNNING);
}


bool RenderingEngine::isPause()
{
    return (Game::getState() == Game::State::PAUSED);
}

void RenderingEngine::processPrevRendering(float aWidth, float aHeight)
{
    glBindFramebuffer(GL_FRAMEBUFFER, mFramebuffer);
//    glViewport(0, 0, aWidth, aHeight);
    glViewport(0, 0, aHeight, aWidth);
    Game::clear(Game::ClearFlags::CLEAR_COLOR_DEPTH, Vector4::zero(), 1.0, 0);
}


#pragma mark - protected


void RenderingEngine::initialize()
{
    //nothing
}


void RenderingEngine::finalize()
{
    //nothing
}


void RenderingEngine::update(float aElapsedTime)
{
 
}


void RenderingEngine::render(float aElapsedTime)
{
    Game::clear(Game::ClearFlags::CLEAR_COLOR_DEPTH, Vector4::zero(), 1.0, 0);
    mKuruScene->render(aElapsedTime);
}


