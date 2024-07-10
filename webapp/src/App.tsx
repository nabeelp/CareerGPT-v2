// Copyright (c) Microsoft. All rights reserved.
import { AuthenticatedTemplate, UnauthenticatedTemplate, useIsAuthenticated, useMsal } from '@azure/msal-react';
import { FluentProvider, Subtitle1, makeStyles, shorthands, tokens } from '@fluentui/react-components';

import * as React from 'react';
import { useEffect } from 'react';
import Chat from './components/chat/Chat';
import { Loading, Login } from './components/views';
import { AuthHelper } from './libs/auth/AuthHelper';
import { useChat, useFile } from './libs/hooks';
import { useAppDispatch, useAppSelector } from './redux/app/hooks';
import { RootState } from './redux/app/store';
import { FeatureKeys } from './redux/features/app/AppState';
import { setActiveUserInfo, setServiceInfo } from './redux/features/app/appSlice';
import { getPathTheme, headerBackgroundColor, headerTextColor } from './styles';

export const useClasses = makeStyles({
    container: {
        display: 'flex',
        flexDirection: 'column',
        height: '100vh',
        width: '100%',
        ...shorthands.overflow('hidden'),
    },
    header: {
        alignItems: 'center',
        backgroundColor: headerBackgroundColor,
        color: headerTextColor,
        display: 'flex',
        height: '48px',
        justifyContent: 'space-between',
        width: '100%',
    },
    persona: {
        marginRight: tokens.spacingHorizontalXXL,
    },
    cornerItems: {
        alignItems: 'center',
        display: 'flex',
        ...shorthands.gap(tokens.spacingHorizontalS),
    },
    logo: {
        height: '35px',
        paddingLeft: tokens.spacingHorizontalXL,
    },
});

export enum AppState {
    ProbeForBackend,
    SettingUserInfo,
    ErrorLoadingChats,
    ErrorLoadingUserInfo,
    LoadingChats,
    Chat,
    SigningOut,
}

const App = () => {
    const classes = useClasses();

    const [appState, setAppState] = React.useState(AppState.ProbeForBackend);
    const dispatch = useAppDispatch();

    const { instance, inProgress } = useMsal();
    const { features, isMaintenance } = useAppSelector((state: RootState) => state.app);
    const isAuthenticated = useIsAuthenticated();

    const chat = useChat();
    const file = useFile();

    useEffect(() => {
        if (isMaintenance && appState !== AppState.ProbeForBackend) {
            setAppState(AppState.ProbeForBackend);
            return;
        }

        if (isAuthenticated && appState === AppState.SettingUserInfo) {
            const account = instance.getActiveAccount();
            if (!account) {
                setAppState(AppState.ErrorLoadingUserInfo);
            } else {
                dispatch(
                    setActiveUserInfo({
                        id: `${account.localAccountId}.${account.tenantId}`,
                        email: account.username, // username is the email address
                        username: account.name ?? account.username,
                    }),
                );

                setAppState(AppState.LoadingChats);
            }
        }

        if ((isAuthenticated || !AuthHelper.isAuthAAD()) && appState === AppState.LoadingChats) {
            void Promise.all([
                // Load all chats from memory
                chat
                    .loadChats()
                    .then(() => {
                        setAppState(AppState.Chat);
                    })
                    .catch(() => {
                        setAppState(AppState.ErrorLoadingChats);
                    }),

                // Check if content safety is enabled
                file.getContentSafetyStatus(),

                // Load service information
                chat.getServiceInfo().then((serviceInfo) => {
                    if (serviceInfo) {
                        dispatch(setServiceInfo(serviceInfo));
                    }
                }),
            ]);
        }

        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [instance, inProgress, isAuthenticated, appState, isMaintenance]);

    const content = <Chat classes={classes} appState={appState} setAppState={setAppState} />;

    const { conversations, selectedId } = useAppSelector((state: RootState) => state.conversations);

    return (
        <FluentProvider
            className="app-container"
            theme={getPathTheme(
                selectedId == '' ? 'careerPlan' : conversations[selectedId].botPath,
                features[FeatureKeys.DarkMode].enabled,
            )}
        >
            {AuthHelper.isAuthAAD() ? (
                <>
                    <UnauthenticatedTemplate>
                        <div className={classes.container}>
                            <div className={classes.header}>
                                <Subtitle1 as="h1">Career Copilot</Subtitle1>
                            </div>
                            {appState === AppState.SigningOut && <Loading text="Signing you out..." />}
                            {appState !== AppState.SigningOut && <Login />}
                        </div>
                    </UnauthenticatedTemplate>
                    <AuthenticatedTemplate>{content}</AuthenticatedTemplate>
                </>
            ) : (
                content
            )}
        </FluentProvider>
    );
};

export default App;
