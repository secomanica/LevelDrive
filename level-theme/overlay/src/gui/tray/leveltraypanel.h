/*
 * SPDX-FileCopyrightText: 2026 Level Tecnologia
 * SPDX-License-Identifier: GPL-2.0-or-later
 *
 * Level Drive tray panel: the window shown when the tray icon is clicked (Windows).
 * Replaces the upstream QMenu popup with a status panel (counters, progress, issues, recent events).
 * Wired in by level-theme/patches/0014-level-tray-panel.patch.
 */

#pragma once

#include "progressdispatcher.h"
#include "syncfileitem.h"
#include "systray.h"

#include <QDate>
#include <QDateTime>
#include <QElapsedTimer>
#include <QHash>
#include <QObject>
#include <QPointer>
#include <QRect>
#include <QVariantList>

#include <optional>

class QQuickWindow;

namespace OCC
{

class Folder;
class User;

class LevelTrayPanel : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString appName READ appName CONSTANT)
    Q_PROPERTY(QString version READ version CONSTANT)
    Q_PROPERTY(QString userName READ userName NOTIFY accountChanged)
    Q_PROPERTY(QString userDetail READ userDetail NOTIFY accountChanged)
    Q_PROPERTY(QString userInitials READ userInitials NOTIFY accountChanged)
    Q_PROPERTY(QString serverName READ serverName NOTIFY accountChanged)
    Q_PROPERTY(bool hasLocalFolder READ hasLocalFolder NOTIFY accountChanged)

    Q_PROPERTY(int state READ state NOTIFY statusChanged)
    Q_PROPERTY(QString statusText READ statusText NOTIFY statusChanged)
    Q_PROPERTY(bool paused READ paused NOTIFY statusChanged)
    Q_PROPERTY(bool canPause READ canPause NOTIFY statusChanged)

    Q_PROPERTY(int queued READ queued NOTIFY countersChanged)
    Q_PROPERTY(int inProgress READ inProgress NOTIFY countersChanged)
    Q_PROPERTY(int completedToday READ completedToday NOTIFY countersChanged)
    Q_PROPERTY(int failures READ failures NOTIFY countersChanged)

    Q_PROPERTY(bool showProgress READ showProgress NOTIFY countersChanged)
    Q_PROPERTY(qint64 progressDone READ progressDone NOTIFY countersChanged)
    Q_PROPERTY(qint64 progressTotal READ progressTotal NOTIFY countersChanged)
    Q_PROPERTY(QString currentItemText READ currentItemText NOTIFY countersChanged)

    Q_PROPERTY(QVariantList issues READ issues NOTIFY countersChanged)
    Q_PROPERTY(bool hasConflicts READ hasConflicts NOTIFY countersChanged)
    Q_PROPERTY(QVariantList events READ events NOTIFY eventsChanged)
    Q_PROPERTY(QString lastUploadText READ lastUploadText NOTIFY countersChanged)

public:
    /// Panel states, mirrored in LevelTrayPanel.qml
    enum State {
        AllSynced = 0,
        Syncing = 1,
        NeedsAttention = 2,
        Paused = 3,
        Offline = 4,
    };
    Q_ENUM(State)

    static LevelTrayPanel *instance();

    /**
     * Shows the panel next to the tray icon.
     * @return true if shown; false if it was intentionally not shown (the click that closed it);
     *         std::nullopt if the panel cannot be used (no account or QML error): fall back to the menu.
     */
    std::optional<bool> show(const QRect &iconRect, Systray::WindowPosition position);
    void hide();
    [[nodiscard]] bool isVisible() const;

    [[nodiscard]] QString appName() const;
    [[nodiscard]] QString version() const;
    [[nodiscard]] QString userName() const;
    [[nodiscard]] QString userDetail() const;
    [[nodiscard]] QString userInitials() const;
    [[nodiscard]] QString serverName() const;
    [[nodiscard]] bool hasLocalFolder() const;

    [[nodiscard]] int state() const;
    [[nodiscard]] QString statusText() const;
    [[nodiscard]] bool paused() const;
    [[nodiscard]] bool canPause() const;

    [[nodiscard]] int queued() const
    {
        return _queued;
    }
    [[nodiscard]] int inProgress() const
    {
        return _inProgress;
    }
    [[nodiscard]] int completedToday() const;
    [[nodiscard]] int failures() const
    {
        return static_cast<int>(_issueList.size());
    }

    [[nodiscard]] bool showProgress() const
    {
        return _progressTotal > 0;
    }
    [[nodiscard]] qint64 progressDone() const
    {
        return _progressDone;
    }
    [[nodiscard]] qint64 progressTotal() const
    {
        return _progressTotal;
    }
    [[nodiscard]] QString currentItemText() const
    {
        return _currentItemText;
    }

    [[nodiscard]] QVariantList issues() const
    {
        return _issueList;
    }
    [[nodiscard]] bool hasConflicts() const
    {
        return _hasConflicts;
    }
    [[nodiscard]] QVariantList events() const
    {
        return _events;
    }
    [[nodiscard]] QString lastUploadText() const;

    Q_INVOKABLE void openFolder();
    Q_INVOKABLE void openInBrowser();
    Q_INVOKABLE void togglePause();
    Q_INVOKABLE void openActivities();
    Q_INVOKABLE void openSettings();
    Q_INVOKABLE void openHelp();
    Q_INVOKABLE void resolveConflicts();
    Q_INVOKABLE void showMoreMenu(const QPointF &globalPos);
    Q_INVOKABLE void close();

Q_SIGNALS:
    void accountChanged();
    void statusChanged();
    void countersChanged();
    void eventsChanged();

private:
    struct Issue {
        QString file;
        QString reason;
        bool conflict = false;
        bool seenThisRun = true;
    };
    struct FolderProgress {
        ProgressInfo::Status status = ProgressInfo::Done;
        qint64 totalFiles = 0;
        qint64 completedFiles = 0;
        int currentItems = 0;
        QString currentFile;
        bool currentUpload = false;
        qint64 currentDone = 0;
        qint64 currentSize = 0;
    };

    explicit LevelTrayPanel(QObject *parent = nullptr);

    bool createWindow();
    void positionWindow();
    void onWindowActiveChanged();

    void onProgressInfo(const QString &folder, const ProgressInfo &progress);
    void onItemCompleted(const QString &folder, const SyncFileItemPtr &item);
    void onCurrentUserChanged();
    void refreshEvents();
    void recompute();

    [[nodiscard]] User *currentUser() const;
    [[nodiscard]] bool isCurrentAccountFolder(const QString &alias) const;
    [[nodiscard]] QString accountKeyForFolder(const QString &alias) const;
    void rollTodayIfNeeded() const;
    void saveToday() const;

    QPointer<QQuickWindow> _window;
    QRect _iconRect;
    Systray::WindowPosition _position = Systray::WindowPosition::Default;
    QElapsedTimer _sinceAutoHide;
    bool _menuOpen = false;

    QHash<QString, FolderProgress> _progress; // by folder alias
    QHash<QString, QHash<QString, Issue>> _issues; // folder alias -> file -> issue
    mutable QDate _todayDate;
    mutable QHash<QString, int> _todayCount; // account id -> files completed today
    QHash<QString, QDateTime> _lastUpload; // account id -> last confirmed upload

    // derived for the current account
    int _queued = 0;
    int _inProgress = 0;
    qint64 _progressDone = 0;
    qint64 _progressTotal = 0;
    QString _currentItemText;
    bool _anyDiscovery = false;
    QVariantList _issueList;
    bool _hasConflicts = false;
    QVariantList _events;
};

}
