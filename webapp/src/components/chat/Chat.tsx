import LogoImage from '../../assets/logo.png';

import { Subtitle1 } from '@fluentui/react-components';
import React from 'react';
import { AuthHelper } from '../..//libs/auth/AuthHelper';
import { AppState, useClasses } from '../../App';
import { UserSettingsMenu } from '../header/UserSettingsMenu';
import { PluginGallery } from '../open-api-plugins/PluginGallery';
import { BackendProbe, ChatView, Error, Loading } from '../views';
import { useAppSelector } from '../../redux/app/hooks';
import { FeatureKeys } from '../../redux/features/app/AppState';
import { RootState } from '../../redux/app/store';

const Chat = ({
    classes,
    appState,
    setAppState,
}: {
    classes: ReturnType<typeof useClasses>;
    appState: AppState;
    setAppState: (state: AppState) => void;
}) => {
    const { features } = useAppSelector((state: RootState) => state.app);
    const onBackendFound = React.useCallback(() => {
        setAppState(
            AuthHelper.isAuthAAD()
                ? // if AAD is enabled, we need to set the active account before loading chats
                  AppState.SettingUserInfo
                : // otherwise, we can load chats immediately
                  AppState.LoadingChats,
        );
        // CUSTOM: Define the company logo and/or name in the divCompanyLogo div below, with the value from LogoImage being defined on line 2 above
    }, [setAppState]);
    return (
        <div className={classes.container}>
            <div className={classes.header}>
                <div className={classes.cornerItems} id="divCompanyLogo">
                    <img className={classes.logo} src={LogoImage} alt="Company logo" />
                    <Subtitle1 as="h1">Contoso</Subtitle1>
                </div>
                <Subtitle1 as="h1">Career Copilot</Subtitle1>
                {appState > AppState.SettingUserInfo && (
                    <div className={classes.cornerItems}>
                        <div className={classes.cornerItems}>
                            {features[FeatureKeys.PluginsPlannersAndPersonas].enabled && (
                                <>
                                    <PluginGallery />
                                </>
                            )}
                            <UserSettingsMenu
                                setLoadingState={() => {
                                    setAppState(AppState.SigningOut);
                                }}
                            />
                        </div>
                    </div>
                )}
            </div>
            {appState === AppState.ProbeForBackend && <BackendProbe onBackendFound={onBackendFound} />}
            {appState === AppState.SettingUserInfo && (
                <Loading text={'Hang tight while we fetch your information...'} />
            )}
            {appState === AppState.ErrorLoadingUserInfo && (
                <Error text={'Unable to load user info. Please try signing out and signing back in.'} />
            )}
            {appState === AppState.ErrorLoadingChats && (
                <Error text={'Unable to load chats. Please try refreshing the page.'} />
            )}
            {appState === AppState.LoadingChats && <Loading text="Loading chats..." />}
            {appState === AppState.Chat && <ChatView />}
        </div>
    );
};
export default Chat;
