//
//  CustomRenderingEngine.cpp
//  B612Mini
//
//  Created by JohnHong on 2018. 5. 8..
//  Copyright © 2018년 Naver. All rights reserved.
//

#include "CustomRenderingEngine.hpp"

using namespace kuru;

static CustomRenderingEngine* mEngineInstance = nullptr;


#pragma mark - init

CustomRenderingEngine* CustomRenderingEngine::getInstance()
{
    if (mEngineInstance == nullptr)
    {
        mEngineInstance = new CustomRenderingEngine();
    }
    
    return mEngineInstance;
}

CustomRenderingEngine::CustomRenderingEngine()
{
    mFramebuffer = 0;
    mColorRenderbuffer = 0;
    mDepthRenderbuffer = 0;
    mFramebufferWidth = 0;
    mFramebufferHeight = 0;
    mKuruScene = NULL;
}


#pragma mark - override


void CustomRenderingEngine::initialize()
{
    //nothing
}


void CustomRenderingEngine::finalize()
{
    SAFE_RELEASE(mKuruScene)
}


void CustomRenderingEngine::update(float aElapsedTime)
{
    if (mKuruScene)
    {
        mKuruScene->update(aElapsedTime);
    }
}


void CustomRenderingEngine::render(float aElapsedTime)
{
    if (mKuruScene)
    {
        mKuruScene->render(aElapsedTime);
    }
}


#pragma mark - public


void CustomRenderingEngine::initKuruScene()
{
    if (mKuruScene)
    {
        SAFE_RELEASE(mKuruScene);
    }
    
    mKuruScene = CustomKuruScene::create();
    mKuruScene->initialize();
}


Node* CustomRenderingEngine::addQuadModelAndNode(float x, float y, float width, float height, float s1, float t1, float s2, float t2)
{
    Mesh* mesh = Mesh::createQuad(x, y, width, height, s1, t1, s2, t2);
    Node* node = addQuadModelAndNode(mesh);
    SAFE_RELEASE(mesh);
    
    return node;
}

Node* CustomRenderingEngine::addCameraFullScreenQuadModelAndNode()
{
    Mesh* mesh = Mesh::createCameraQuadFullscreen();
    Node* node = addQuadModelAndNode(mesh);
    SAFE_RELEASE(mesh);
    
    return node;
}


bool CustomRenderingEngine::attachColorAndDepthBuffer()
{
    GL_ASSERT( glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, mColorRenderbuffer) );
    
    // Retrieve framebuffer size
    GL_ASSERT( glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &mFramebufferWidth) );
    GL_ASSERT( glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &mFramebufferHeight) );
    
    GL_ASSERT( glGenRenderbuffers(1, &mDepthRenderbuffer) );
    GL_ASSERT( glBindRenderbuffer(GL_RENDERBUFFER, mDepthRenderbuffer) );
    GL_ASSERT( glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT24_OES, mFramebufferWidth, mFramebufferHeight) );
    GL_ASSERT( glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, mDepthRenderbuffer) );

    // Sanity check, ensure that the framebuffer is valid
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
    {
        this->deleteFramebuffer();
        
        return false;
    }

    return true;
}


void CustomRenderingEngine::createFrameAndColorRenderbuffer()
{
    // iOS Requires all content go to a rendering buffer then it is swapped into the windows rendering surface
    assert(mFramebuffer == 0);
    
    // Create the default frame buffer
    GL_ASSERT( glGenFramebuffers(1, &mFramebuffer) );
    GL_ASSERT( glBindFramebuffer(GL_FRAMEBUFFER, mFramebuffer) );
    
    // Create a color buffer to attach to the frame buffer
    GL_ASSERT( glGenRenderbuffers(1, &mColorRenderbuffer) );
    GL_ASSERT( glBindRenderbuffer(GL_RENDERBUFFER, mColorRenderbuffer) );
}


void CustomRenderingEngine::deleteFramebuffer()
{
    if (mFramebuffer)
    {
        GL_ASSERT( glDeleteFramebuffers(1, &mFramebuffer) );
        mFramebuffer = 0;
    }
    if (mColorRenderbuffer)
    {
        GL_ASSERT( glDeleteRenderbuffers(1, &mColorRenderbuffer) );
        mColorRenderbuffer = 0;
    }
    if (mDepthRenderbuffer)
    {
        GL_ASSERT( glDeleteRenderbuffers(1, &mDepthRenderbuffer) );
        mDepthRenderbuffer = 0;
    }
}


void CustomRenderingEngine::applyViewport()
{
    GL_ASSERT( glViewport(0, 0, mFramebufferWidth, mFramebufferHeight) );
}


void CustomRenderingEngine::bindFramebuffer()
{
    GL_ASSERT( glBindFramebuffer(GL_FRAMEBUFFER, mFramebuffer) );
}


void CustomRenderingEngine::bindColorRenderbuffer()
{
    GL_ASSERT( glBindRenderbuffer(GL_RENDERBUFFER, mColorRenderbuffer) );
}


#pragma mark - private


Node* CustomRenderingEngine::addQuadModelAndNode(Mesh* mesh)
{
    Model* model = Model::create(mesh);
    Node* node = mKuruScene->addNodeWithModel(model);
    SAFE_RELEASE(model);
    
    return node;
}
